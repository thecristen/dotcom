defmodule Site.TripPlan.Query do
  alias TripPlan.Itinerary
  alias Stops.Position

  @enforce_keys [:from, :to, :itineraries]
  defstruct [:from,
             :to,
             :itineraries,
             time: :unknown,
             wheelchair_accessible?: false]

  @type t :: %__MODULE__{
    from: Position.t,
    to: Position.t,
    time: :unknown | {:depart_at | :arrive_by, DateTime.t},
    wheelchair_accessible?: boolean,
    itineraries: {:ok, [Itinerary.t]} | {:error, any}
  }

  @spec from_query(map) :: t
  def from_query(query) do
    from = location(query, :from)
    to = location(query, :to)
    opts = opts_from_query(query)
    itineraries = fetch_itineraries(from, to, opts)

    itineraries
    |> build_query(from, to)
    |> include_options(opts)
    |> suggest_alternate_locations
  end

  defp fetch_itineraries(from, to, opts) do
    if Keyword.get(opts, :wheelchair_accessible?) do
      do_fetch_itineraries(from, to, opts)
    else
      accessible_opts = Keyword.put(opts, :wheelchair_accessible?, true)
      accessible_request = Task.async(fn -> do_fetch_itineraries(from, to, accessible_opts) end)

      from
      |> do_fetch_itineraries(to, opts)
      |> dedup_itineraries(Task.await(accessible_request))
    end
  end

  defp do_fetch_itineraries(from, to, opts) do
    with {:ok, from} <- from,
    {:ok, to} <- to do
      TripPlan.plan(from, to, opts)
    else
      _ -> {:error, :prereq}
    end
  end

  defp dedup_itineraries({:error, _status} = response, {:error, _accessible_response}), do: response
  defp dedup_itineraries(inaccessible, {:error, _response}), do: inaccessible
  defp dedup_itineraries({:error, _response}, {:ok, _itineraries} = accessible), do: accessible
  defp dedup_itineraries({:ok, inaccessible}, {:ok, accessible}) do
    {:ok, keep_unique(inaccessible, accessible, &Itinerary.same_itinerary?/2)}
  end

  defp keep_unique(inaccessible, accessible, compare_fn) do
    accessible_duplicate? = fn itinerary -> &Enum.any?(accessible, compare_fn.(&1, itinerary)) end
    unique_inaccessible = Enum.reject(inaccessible, accessible_duplicate?)
    Enum.concat(accessible, unique_inaccessible)
  end

  @spec build_query(TripPlan.Api.t, Position.t, Position.t) :: t
  defp build_query(itineraries, from, to) do
    %__MODULE__{
      from: from,
      to: to,
      itineraries: itineraries
    }
  end

  defp include_options(query, opts) do
    time = cond do
      dt = opts[:arrive_by] ->
        {:arrive_by, dt}
      dt = opts[:depart_at] ->
        {:depart_at, dt}
      true ->
        {:depart_at, Util.now}
    end
    %{query |
      time: time,
      wheelchair_accessible?: opts[:wheelchair_accessible?] == true
    }
  end

  @spec location(map, :from | :to) :: TripPlan.Geocode.t
  defp location(query, terminus) do
    key = Atom.to_string(terminus)
    location = Map.get(query, key, "")

    case fetch_lat_lng(query, key) do
      {:ok, latitude, longitude} ->
        {:ok,
          %TripPlan.NamedPosition{
            name: location,
            latitude: latitude,
            longitude: longitude
          }
        }
      _ ->
        TripPlan.geocode(location)
    end
  end

  @spec fetch_lat_lng(map, String.t) :: {:ok, float, float} | :error
  def fetch_lat_lng(query, key) do
    with {:ok, lat} <- optional_float(Map.get(query, "#{key}_latitude")),
         {:ok, lng} <- optional_float(Map.get(query, "#{key}_longitude")) do
           {:ok, lat, lng}
    else
      _ -> :error
    end
  end

  defp optional_float(binary) when is_binary(binary) do
    case Float.parse(binary) do
      {float, ""} -> {:ok, float}
      _ -> :error
    end
  end
  defp optional_float(_), do: :error

  @spec opts_from_query(%{optional(String.t) => String.t}, Keyword.t) :: Keyword.t
  defp opts_from_query(query, opts \\ [])
  defp opts_from_query(%{"time" => "depart", "date_time" => _date_time} = query, opts) do
    do_date_time(:depart_at, query, opts)
  end
  defp opts_from_query(%{"time" => "arrive", "date_time" => _date_time} = query, opts) do
    do_date_time(:arrive_by, query, opts)
  end
  defp opts_from_query(%{"accessible" => "true"} = query, opts) do
    opts_from_query(
      Map.delete(query, "accessible"),
      Keyword.put(opts, :wheelchair_accessible?, true)
    )
  end
  defp opts_from_query(_, opts) do
      opts
  end

  defp do_date_time(param, %{"date_time" => date_time} = query, opts) do
    opts_from_query(
      Map.drop(query, ["time", "date_time"]),
      Keyword.put(opts, param, date_time))
  end

  @doc "Determines if the given query contains any itineraries"
  @spec itineraries?(t | nil) :: boolean
  def itineraries?(%__MODULE__{itineraries: {:ok, itineraries}}) do
    !Enum.empty?(itineraries)
  end
  def itineraries?(_query), do: false

  @spec get_itineraries(t) :: [Itinerary.t]
  def get_itineraries(%__MODULE__{itineraries: {:ok, itineraries}}) do
    itineraries
  end
  def get_itineraries(%__MODULE__{itineraries: {:error, _}}) do
    []
  end

  @doc "Returns the name of the location for a given query"
  @spec location_name(t, :from | :to) :: String.t
  def location_name(%__MODULE__{} = query, key) when key in [:from, :to] do
    case Map.get(query, key) do
      {:ok, position} -> position.name
      _ -> nil
    end
  end

  @spec suggest_alternate_locations(t) :: t
  defp suggest_alternate_locations(%__MODULE__{itineraries: {:error, error}, from: {:ok, from}, to: {:ok, to}} = query)
  when error in [:path_not_found, :location_not_accessible] do
    [froms, tos] =
      [from, to]
      |> Task.async_stream(&TripPlan.stops_nearby/1)
      |> Enum.zip([from, to])
      |> Enum.map(fn {results, original} ->
        case results do
          {:ok, {:ok, [_ | _] = results}} -> {:error, {:multiple_results, Enum.take(results, 5)}}
          _ -> {:ok, original}
        end
      end)

    %__MODULE__{query |
      from: froms,
      to: tos
    }
  end
  defp suggest_alternate_locations(query), do: query
end
