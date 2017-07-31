defmodule Site.TripPlan.Query do
  alias TripPlan.{Itinerary, Geocode}

  @enforce_keys [:from, :to, :itineraries]
  defstruct [:from, :to, :itineraries]

  @type t :: %__MODULE__{
    from: Geocode.t,
    to: Geocode.t,
    itineraries: {:ok, [Itinerary.t]} | {:error, any}
  }

  def from_query(query) do
    from = location(query, :from)
    to = location(query, :to)
    itineraries = with {:ok, opts} <- opts_from_query(query),
                       {:ok, from} <- from,
                       {:ok, to} <- to do
                    TripPlan.plan(from, to, opts)
                  else
                    _ -> {:error, :prereq}
                  end

    itineraries
    |> build_query(from, to)
    |> suggest_alternate_locations
  end

  defp build_query(itineraries, from, to) do
    %__MODULE__{
      from: from,
      to: to,
      itineraries: itineraries
    }
  end

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
      {:ok, opts}
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

  @doc "Returns the name of the location for a given query"
  @spec location_name(t, :from | :to) :: String.t
  def location_name(%__MODULE__{} = query, key) when key in [:from, :to] do
    case Map.get(query, key) do
      {:ok, position} -> position.name
      _ -> nil
    end
  end

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
