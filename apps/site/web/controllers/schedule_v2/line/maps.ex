defmodule Site.ScheduleV2Controller.Line.Maps do
  alias GoogleMaps.MapData
  alias GoogleMaps.MapData.{Path, Marker}
  alias Stops.{RouteStops, RouteStop}
  alias Routes.{Route, Shape}
  alias Site.MapHelpers
  alias Stops.Position
  import Site.Router.Helpers
  import Routes.Route, only: [vehicle_atom: 1]

  @moduledoc """
  Handles Map information for the line controller
  """

  def map_img_src(_, _, %Routes.Route{type: 4}, _path_color) do
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end
  def map_img_src({route_stops, _shapes}, polylines, _route, path_color) do
    icon = MapHelpers.map_stop_icon_path(:tiny)
    markers = build_stop_markers(route_stops, icon, true)
    paths = Enum.map(polylines, &Path.new(&1, color: path_color))

    {600, 600}
    |> MapData.new
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> GoogleMaps.static_map_url()
  end

  # Floors the lat/lng when given an (optional) true boolean
  defp build_stop_markers(route_stops, icon, floor_position?) do
    Enum.map(route_stops, &build_stop_marker(&1, icon, floor_position?))
  end

  defp build_stop_marker(route_stop, icon, true) do
    floored_lat = route_stop |> Position.latitude() |> floor_position()
    floored_lng = route_stop |> Position.longitude() |> floor_position()
    Marker.new(floored_lat, floored_lng, icon: icon, tooltip: route_stop.name, size: :tiny)
  end
  defp build_stop_marker(route_stop, icon, false) do
    latitude = Position.latitude(route_stop)
    longitude = Position.longitude(route_stop)
    Marker.new(latitude, longitude, icon: icon, tooltip: route_stop.name, size: :tiny)
  end

  @spec floor_position(float) :: float
  defp floor_position(position) do
    Float.floor(position, 4)
  end

  @spec dynamic_map_data(String.t, [String.t], {[RouteStop.t], any}, {[String.t], map(), String.t}) :: MapData.t
  def dynamic_map_data(color, map_polylines, {route_stops, _shapes}, {vehicle_polylines, vehicle_tooltips, vehicle_icon}) do
    markers = dynamic_markers(route_stops, vehicle_tooltips, vehicle_icon)
    paths = dynamic_paths(color, map_polylines, vehicle_polylines)

    {600, 600}
    |> MapData.new
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> MapData.disable_map_type_controls
  end

  defp dynamic_markers(route_stops, vehicle_tooltips, vehicle_icon) do
    vehicle_markers = vehicle_tooltips |> get_vehicles |> build_vehicle_markers(vehicle_icon)
    stop_markers = Enum.map(route_stops, &build_stop_marker(&1, dynamic_stop_icon(&1.is_terminus?), false))
    stop_markers ++ vehicle_markers
  end

  defp dynamic_paths(color, route_polylines, vehicle_polylines) do
    route_paths = Enum.map(route_polylines, &Path.new(&1, color: color, weight: 4))
    vehicle_paths = Enum.map(vehicle_polylines, &Path.new(&1, color: color, weight: 2))
    route_paths ++ vehicle_paths
  end

  defp build_vehicle_markers(vehicles, icon) do
    Enum.map(vehicles, &build_vehicle_marker(&1, icon))
  end

  defp build_vehicle_marker({lat, lng, tooltip_content}, icon) do
    floored_lat = floor_position(lat)
    floored_lng = floor_position(lng)
    Marker.new(floored_lat, floored_lng, icon: icon, tooltip: tooltip_content)
  end

  @spec dynamic_stop_icon(boolean) :: String.t
  defp dynamic_stop_icon(true), do: "000000-dot-filled"
  defp dynamic_stop_icon(false), do: "000000-dot"

  @spec get_vehicles(nil | map()) :: [{float, float, String.t}]
  defp get_vehicles(nil), do: []
  defp get_vehicles(vehicle_tooltips) do
    vehicle_tooltips
    |> Enum.reject(&match?({{_trip, _id}, _tooltip}, &1))
    |> Enum.map(&do_get_vehicles/1)
  end

  defp do_get_vehicles({_, %VehicleTooltip{vehicle: vehicle} = tooltip}) do
    {vehicle.latitude, vehicle.longitude, VehicleHelpers.tooltip(tooltip)}
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
    vehicle_icon = "#{vehicle_atom(route.type)}-vehicle"
    vehicle_data = {vehicle_polylines, vehicle_tooltips, vehicle_icon}
    dynamic_data = dynamic_map_data(color, map_polylines, map_route_stops, vehicle_data)
    {static_data, dynamic_data}
  end

  @spec map_polylines({any, [Routes.Shape.t]}, Route.t) :: [String.t]
  defp map_polylines(_, %Routes.Route{type: 4}), do: []
  defp map_polylines({_stops, shapes}, _) do
    shapes
    |> Enum.flat_map(& PolylineHelpers.condense([&1.polyline]))
  end

  @doc "Returns the stops that should be displayed on the map"
  @spec map_stops([RouteStops.t], {[Shape.t], [Shape.t]}, Route.id_t) :: {[Stops.Stop.t], [Shape.t]}
  def map_stops(branches, {route_shapes, _active_shapes}, "Green") do
    {do_map_stops(branches), route_shapes}
  end
  def map_stops(branches, {_route_shapes, active_shapes}, _route_id) do
    {do_map_stops(branches), active_shapes}
  end

  @spec do_map_stops([RouteStops.t]) :: [RouteStop.t]
  defp do_map_stops(branches) do
    branches
    |> Enum.flat_map(& &1.stops)
    |> Enum.uniq_by(& &1.id)
  end
end
