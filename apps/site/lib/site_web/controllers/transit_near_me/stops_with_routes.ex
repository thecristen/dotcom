defmodule SiteWeb.TransitNearMeController.StopsWithRoutes do
  @moduledoc """
  Builds a list of stops near a location, with the routes that go through that stop.
  """
  alias Routes.Route
  alias SiteWeb.TransitNearMeController.RoutesAndStops
  alias Stops.Stop

  @type route_group :: {
          Route.gtfs_route_type() | Route.subway_lines_type(),
          [Route.t()]
        }

  @type stop_with_routes :: %{
          distance: float(),
          routes: [route_group],
          stop: Stop.t()
        }

  @spec from_routes_and_stops(RoutesAndStops.t()) :: [stop_with_routes]
  def from_routes_and_stops(%RoutesAndStops{stops: stops_with_distances} = routes_and_stops) do
    stops_with_distances
    |> Map.values()
    |> Task.async_stream(&build_stop_with_routes(&1, routes_and_stops))
    |> Enum.map(fn {:ok, map} -> map end)
  end

  @spec build_stop_with_routes(RoutesAndStops.stop_with_distance_t(), RoutesAndStops.t()) ::
          stop_with_routes
  defp build_stop_with_routes(
         %{stop: stop, distance: distance},
         %RoutesAndStops{} = routes_and_stops
       ) do
    grouped_routes =
      stop.id
      |> routes_for_stop(routes_and_stops)
      |> get_route_groups()

    %{
      stop: stop,
      distance: distance,
      routes: grouped_routes
    }
  end

  @spec routes_for_stop(String.t(), RoutesAndStops.t()) :: [Route.t()]
  defp routes_for_stop(stop_id, %RoutesAndStops{routes: routes, join: join}) do
    join
    |> Enum.filter(&(&1.stop_id == stop_id))
    |> Enum.map(& &1.route_id)
    |> Enum.map(&routes[&1])
  end

  @spec get_route_groups([Route.t()]) :: [Routes.Group.t()]
  defp get_route_groups(route_list) do
    route_list
    |> Enum.group_by(&Route.type_atom/1)
    |> Keyword.new()
    |> separate_subway_lines()
    |> Keyword.delete(:subway)
  end

  @doc """
    Returns the grouped routes list with subway lines elevated to the top level, eg:

      separate_subway_lines([commuter: [_], bus: [_], subway: [orange_line, red_line])
      # =>   [commuter: [commuter_lines], bus: [bus_lines], orange: [orange_line], red: [red_line]]

  """
  @spec separate_subway_lines([Routes.Group.t()]) :: [
          {Routes.Route.gtfs_route_type() | Route.subway_lines_type(), [Route.t()]}
        ]
  def separate_subway_lines(routes) do
    routes
    |> Keyword.get(:subway, [])
    |> Enum.reduce(routes, &subway_reducer/2)
  end

  @spec subway_reducer(Route.t(), [Routes.Group.t()]) :: [
          {Routes.Route.subway_lines_type(), [Route.t()]}
        ]
  defp subway_reducer(%Route{id: id, type: 1} = route, routes) do
    Keyword.put(routes, id |> Kernel.<>("_line") |> String.downcase() |> String.to_atom(), [route])
  end

  defp subway_reducer(%Route{name: "Green" <> _} = route, routes) do
    Keyword.put(routes, :green_line, [Route.to_naive(route)])
  end

  defp subway_reducer(%Route{id: "Mattapan"} = route, routes) do
    Keyword.put(routes, :mattapan_trolley, [route])
  end
end
