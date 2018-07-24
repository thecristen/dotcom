defmodule Site.TripPlan.Query do
  alias TripPlan.{Itinerary, NamedPosition}
  alias Util.Position

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
    itineraries: TripPlan.Api.t
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

  @spec fetch_itineraries(TripPlan.Geocode.t, TripPlan.Geocode.t, Keyword.t) :: TripPlan.Api.t
  defp fetch_itineraries(from, to, opts) do
    if Keyword.get(opts, :wheelchair_accessible?) do
      do_fetch_itineraries(from, to, opts)
    else
      accessible_opts = Keyword.put(opts, :wheelchair_accessible?, true)

      [mixed_results, accessible_results] = Util.async_with_timeout([
        fn -> do_fetch_itineraries(from, to, opts) end,
        fn -> do_fetch_itineraries(from, to, accessible_opts) end,
      ], {:error, :timeout})

      dedup_itineraries(mixed_results, accessible_results)
    end
  end

  @spec do_fetch_itineraries(TripPlan.Geocode.t, TripPlan.Geocode.t, Keyword.t) :: TripPlan.Api.t
  defp do_fetch_itineraries(from, to, opts) do
    with {:ok, from} <- from,
    {:ok, to} <- to do
      TripPlan.plan(from, to, opts)
    else
      _ -> {:error, :prereq}
    end
  end

  @spec dedup_itineraries(TripPlan.Api.t, TripPlan.Api.t) :: TripPlan.Api.t
  defp dedup_itineraries({:error, _status} = response, {:error, _accessible_response}), do: response
  defp dedup_itineraries(unknown, {:error, _response}), do: unknown
  defp dedup_itineraries({:error, _response}, {:ok, _itineraries} = accessible), do: accessible
  defp dedup_itineraries({:ok, unknown}, {:ok, accessible}) do
    merged = Site.TripPlan.Merge.merge_itineraries(
      accessible,
      unknown)
    {:ok, merged}
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
  defp opts_from_query(%{"time" => "leave-now", "date_time" => _date_time} = query, opts) do
    do_date_time(:depart_at, query, opts)
  end
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
  defp opts_from_query(%{"modes" => modes} = query, opts) do
    opts_from_query(
      Map.delete(query, "modes"),
      get_mode_opts(modes, opts)
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

  @spec get_mode_opts(map, Keyword.t) :: Keyword.t
  def get_mode_opts(%{} = modes, opts) do
    active_modes = Enum.reduce(modes, [], &get_active_modes/2)
    Keyword.put(opts, :mode, active_modes)
  end

  @spec get_active_modes({String.t, String.t}, Keyword.t) :: Keyword.t
  defp get_active_modes({"subway", "true"}, acc) do
    ["TRAM", "SUBWAY" | acc]
  end
  defp get_active_modes({"commuter_rail", "true"}, acc) do
    ["RAIL" | acc]
  end
  defp get_active_modes({"bus", "true"}, acc) do
    ["BUS" | acc]
  end
  defp get_active_modes({"ferry", "true"}, acc) do
    ["FERRY" | acc]
  end
  defp get_active_modes({_, "false"}, acc) do
    acc
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

  @spec suggest_alternate_locations(t, non_neg_integer) :: t
  def suggest_alternate_locations(query, timeout \\ 5_000)
  def suggest_alternate_locations(%__MODULE__{itineraries: {:error, error}, from: {:ok, from}, to: {:ok, to}} = query, timeout)
  when error in [:path_not_found, :location_not_accessible] do
    %{from: froms, to: tos} = Util.yield_or_default_many(%{
      Task.async(TripPlan, :stops_nearby, [from]) => {:from, from},
      Task.async(TripPlan, :stops_nearby, [to]) => {:to, to}
    }, timeout)
    %__MODULE__{query | from: check_alternate_locations(froms, from), to: check_alternate_locations(tos, to)}
  end
  def suggest_alternate_locations(query, _timeout), do: query

  defp check_alternate_locations({:ok, [_ | _] = locations}, _) do
    {:error, {:multiple_results, Enum.take(locations, 5)}}
  end
  defp check_alternate_locations({:ok, _}, default) do
    {:ok, default}
  end
  defp check_alternate_locations(%NamedPosition{} = position, _) do
    {:ok, position}
  end
  defp check_alternate_locations({:error, _error}, default) do
    {:ok, default}
  end
end
