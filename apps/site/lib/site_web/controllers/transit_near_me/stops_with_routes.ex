defmodule SiteWeb.TransitNearMeController.StopsWithRoutes do
  @moduledoc """
  Builds a list of stops near a location, with the routes that go through that stop.
  """
  alias GoogleMaps.{Geocode, Geocode.Address}
  alias Routes.{Repo, Route}
  alias Stops.{Nearby, Stop}
  alias Util.Distance

  @type route_group :: {
          Route.gtfs_route_type() | Route.subway_lines_type(),
          [Route.t()]
        }

  @type stop_with_routes :: %{
          distance: float(),
          routes: [route_group],
          stop: Stop.t()
        }

  @spec get(GoogleMaps.Geocode.Address.t(), Keyword.t()) :: [stop_with_routes]
  def get(location, opts) do
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

    location
    |> nearby_fn.()
    |> stops_with_routes(location, routes_by_stop_fn)
  end

  @spec stops_with_routes([Stop.t()], Geocode.Address.t(), (String.t() -> [Route.t()])) :: [
          stop_with_routes
        ]
  defp stops_with_routes(stops, location, routes_by_stop_fn) do
    stops
    |> Task.async_stream(&build_stop_with_routes(&1, location, routes_by_stop_fn))
    |> Enum.map(fn {:ok, map} -> map end)
  end

  @spec build_stop_with_routes(Stops.Stop.t(), GoogleMaps.Geocode.Address.t(), (any() -> any())) ::
          stop_with_routes
  def build_stop_with_routes(%Stop{} = stop, %Address{} = location, routes_by_stop_fn) do
    %{
      stop: stop,
      distance: Distance.haversine(stop, location),
      routes:
        stop.id
        |> routes_by_stop_fn.()
        |> get_route_groups()
    }
  end

  @spec get_route_groups([Route.t()]) :: [Routes.Group.t()]
  def get_route_groups(route_list) do
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
