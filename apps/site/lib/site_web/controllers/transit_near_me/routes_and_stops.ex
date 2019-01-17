defmodule SiteWeb.TransitNearMeController.RoutesAndStops do
  @moduledoc """
  Structure data connecting local routes and stops with each other.
  """
  alias GoogleMaps.Geocode.Address
  alias Routes.{Repo, Route}
  alias Stops.{Nearby, Stop}
  alias Util.Distance

  defstruct routes: %{},
            stops: %{},
            join: []

  @type routes_map :: %{String.t() => Route.t()}

  @type stop_with_distance_t :: %{
          stop: Stop.t(),
          distance: float()
        }

  @type stops_map :: %{String.t() => stop_with_distance_t}

  @type route_stop_connection :: %{
          route_id: String.t(),
          stop_id: String.t()
        }

  @type t :: %__MODULE__{
          routes: routes_map,
          stops: stops_map,
          join: [route_stop_connection]
        }

  @type stops_nearby_fn_t :: (Address.t() -> [Stop.t()])
  @type routes_by_stop_fn_t :: (String.t() -> [Route.t()])

  @type stop_to_routes_map :: %{String.t() => [Route.t()]}

  @spec get(GoogleMaps.Geocode.Address.t(), Keyword.t()) :: t
  def get(location, opts) do
    {nearby_fn, routes_by_stop_fn} = api_functions(opts)

    stops_map =
      location
      |> nearby_fn.()
      |> stops_with_distances(location)
      |> map_stops()

    routes_for_stops = routes_for_stops(Map.keys(stops_map), routes_by_stop_fn)

    routes_map =
      routes_for_stops
      |> Map.values()
      |> List.flatten()
      |> map_routes()

    joined_stop_route_ids = join_stop_route_ids(routes_for_stops)

    %__MODULE__{
      routes: routes_map,
      stops: stops_map,
      join: joined_stop_route_ids
    }
  end

  @spec api_functions(Keyword.t()) :: {stops_nearby_fn_t, routes_by_stop_fn_t}
  defp api_functions(opts) do
    opts =
      Keyword.merge(
        [
          stops_nearby_fn: &Nearby.nearby/1,
          routes_by_stop_fn: &Repo.by_stop/1
        ],
        opts
      )

    nearby_fn = Keyword.fetch!(opts, :stops_nearby_fn)
    routes_by_stop_fn = Keyword.fetch!(opts, :routes_by_stop_fn)

    {nearby_fn, routes_by_stop_fn}
  end

  @spec stops_with_distances([Stop.t()], GoogleMaps.Geocode.Address.t()) :: [stop_with_distance_t]
  defp stops_with_distances(stops, %Address{} = location) do
    stops
    |> Task.async_stream(&stop_with_distance(&1, location))
    |> Enum.map(fn {:ok, map} -> map end)
  end

  @spec stop_with_distance(Stops.Stop.t(), GoogleMaps.Geocode.Address.t()) :: stop_with_distance_t
  defp stop_with_distance(%Stop{} = stop, %Address{} = location) do
    %{
      stop: stop,
      distance: Distance.haversine(stop, location)
    }
  end

  @spec routes_for_stops([String.t()], routes_by_stop_fn_t) :: stop_to_routes_map
  defp routes_for_stops(stop_ids, routes_by_stop_fn) do
    stop_ids
    |> Task.async_stream(&{&1, routes_by_stop_fn.(&1)})
    |> Map.new(fn {:ok, stop_routes} -> stop_routes end)
  end

  @spec map_routes([Route.t()]) :: routes_map
  defp map_routes(routes) do
    Map.new(routes, &{&1.id, &1})
  end

  @spec map_stops([stop_with_distance_t]) :: stops_map
  defp map_stops(nearby_stops_with_distances) do
    Map.new(nearby_stops_with_distances, &{&1.stop.id, &1})
  end

  @spec join_stop_route_ids(stop_to_routes_map) :: [route_stop_connection]
  defp join_stop_route_ids(routes_for_stops) do
    Enum.reduce(routes_for_stops, [], fn {stop_id, routes}, acc ->
      Enum.reduce(routes, acc, fn route, routes_acc ->
        [%{route_id: route.id, stop_id: stop_id} | routes_acc]
      end)
    end)
  end
end
