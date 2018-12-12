defmodule SiteWeb.ScheduleController.Line.Maps do
  alias GoogleMaps.MapData
  alias GoogleMaps.MapData.{Path, Marker, Padding}
  alias Stops.{RouteStops, RouteStop}
  alias Routes.{Shape, Route}
  alias Site.MapHelpers

  @moduledoc """
  Handles Map information for the line controller
  """

  def map_img_src(_, _, %Routes.Route{type: 4}, _path_color) do
    MapHelpers.image(:ferry)
  end

  def map_img_src({route_stops, _shapes}, polylines, _route, path_color) do
    markers = Enum.map(route_stops, &build_stop_marker/1)
    paths = Enum.map(polylines, &Path.new(&1, color: path_color))

    {600, 600}
    |> MapData.new()
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> GoogleMaps.static_map_url()
  end

  @spec build_stop_marker(RouteStop.t()) :: Marker.t()
  defp build_stop_marker(stop)

  defp build_stop_marker(%RouteStop{} = stop) do
    stop.id
    |> Stops.Repo.get()
    |> MapHelpers.Markers.stop(stop.is_terminus?)
  end

  @spec dynamic_map_data(
          String.t(),
          [String.t()],
          {[RouteStop.t()], any},
          {[String.t()], VehicleHelpers.tooltip_index()}
        ) :: MapData.t()
  def dynamic_map_data(
        color,
        map_polylines,
        {route_stops, _shapes},
        {vehicle_polylines, vehicle_tooltips}
      ) do
    markers = dynamic_markers(route_stops, vehicle_tooltips)
    paths = dynamic_paths(color, map_polylines, vehicle_polylines)

    {600, 600}
    |> MapData.new()
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> MapData.disable_map_type_controls()
    |> MapData.bound_padding(%Padding{})
    |> MapData.default_center(nil)
  end

  @spec dynamic_markers([RouteStop.t()], VehicleHelpers.tooltip_index()) :: [Marker.t()]
  defp dynamic_markers(route_stops, tooltip_index) do
    vehicle_markers = build_vehicle_markers(tooltip_index)
    stop_markers = Enum.map(route_stops, &build_stop_marker/1)
    stop_markers ++ vehicle_markers
  end

  @spec build_vehicle_markers(VehicleHelpers.tooltip_index()) :: [Marker.t()]
  defp build_vehicle_markers(tooltip_index) do
    # the tooltip index uses two different key formats, so
    # the Enum.reject call here is essentially just
    # deduplicating the index
    tooltip_index
    |> Enum.reject(&match?({{_trip, _id}, _tooltip}, &1))
    |> Enum.map(fn {_, vt} -> MapHelpers.Markers.vehicle(vt) end)
  end

  defp dynamic_paths(color, route_polylines, vehicle_polylines) do
    route_paths = Enum.map(route_polylines, &Path.new(&1, color: color, weight: 4))
    vehicle_paths = Enum.map(vehicle_polylines, &Path.new(&1, color: color, weight: 2))
    route_paths ++ vehicle_paths
  end

  @doc """
  Returns a tuple {String.t, MapData.t} where the first element
  is the url for the static map, and the second element is the MapData
  struct used to build the dynamic map
  """
  def map_data(route, map_route_stops, vehicle_polylines, vehicle_tooltips) do
    color = MapHelpers.route_map_color(route)
    map_polylines = map_polylines(map_route_stops, route)
    static_data = map_img_src(map_route_stops, map_polylines, route, color)
    vehicle_data = {vehicle_polylines, vehicle_tooltips}
    dynamic_data = dynamic_map_data(color, map_polylines, map_route_stops, vehicle_data)
    {static_data, dynamic_data}
  end

  @spec map_polylines({any, [Routes.Shape.t()]}, Route.t()) :: [String.t()]
  defp map_polylines(_, %Routes.Route{type: 4}), do: []

  defp map_polylines({_stops, shapes}, _) do
    shapes
    |> Enum.flat_map(&PolylineHelpers.condense([&1.polyline]))
  end

  @doc "Returns the stops that should be displayed on the map"
  @spec map_stops([RouteStops.t()], {[Shape.t()], [Shape.t()]}, Route.id_t()) ::
          {[Stops.Stop.t()], [Shape.t()]}
  def map_stops(branches, {route_shapes, _active_shapes}, "Green") do
    {do_map_stops(branches), route_shapes}
  end

  def map_stops(branches, {_route_shapes, active_shapes}, _route_id) do
    {do_map_stops(branches), active_shapes}
  end

  @spec do_map_stops([RouteStops.t()]) :: [RouteStop.t()]
  defp do_map_stops(branches) do
    branches
    |> Enum.flat_map(& &1.stops)
    |> Enum.uniq_by(& &1.id)
  end
end
