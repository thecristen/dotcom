defmodule SiteWeb.TransitNearMeController.RoutesWithStops do
  @moduledoc """
  Take a list of stops with routes and invert the data structure.
  """
  alias Routes.Route
  alias SiteWeb.TransitNearMeController.RoutesAndStops

  @type route_with_stops :: %{
          route: Route.t(),
          stops: [RoutesAndStops.stop_with_distance_t()]
        }

  @doc """
  Transform routes_and_stops data to a list of routes_with_stops
  """
  @spec from_routes_and_stops(RoutesAndStops.t()) :: [route_with_stops]
  def from_routes_and_stops(%RoutesAndStops{routes: routes} = routes_and_stops) do
    routes
    |> Map.values()
    |> Task.async_stream(&build_route_with_stops(&1, routes_and_stops))
    |> Enum.map(fn {:ok, map} -> map end)
  end

  @spec build_route_with_stops(Route.t(), RoutesAndStops.t()) :: route_with_stops
  defp build_route_with_stops(route, routes_and_stops) do
    %{
      route: route,
      stops: stops_for_route(route.id, routes_and_stops)
    }
  end

  @spec stops_for_route(String.t(), RoutesAndStops.t()) :: [RoutesAndStops.stop_with_distance_t()]
  defp stops_for_route(route_id, %RoutesAndStops{stops: stops, join: join}) do
    join
    |> Enum.filter(&(&1.route_id == route_id))
    |> Enum.map(&stops[&1.stop_id])
  end
end
