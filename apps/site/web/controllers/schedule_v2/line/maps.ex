defmodule Site.ScheduleV2Controller.Line.Maps do
  alias GoogleMaps.MapData
  alias GoogleMaps.MapData.{Path, Marker}
  alias Routes.{Route, Shape}
  import Site.Router.Helpers

  @moduledoc """
  Handles Map information for the line controller
  """

  def map_img_src(_, _, %Routes.Route{type: 4}, _path_color) do
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end
  def map_img_src({stops, _shapes}, polylines, route, path_color) do
    icon = MapHelpers.map_stop_icon_path(route)
    markers = build_stop_markers(stops, icon, true)
    paths = Enum.map(polylines, &Path.new(&1, path_color))

    {600, 600}
    |> MapData.new
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> GoogleMaps.static_map_url()
  end

  # Floors the lat/lng when given an (optional) true boolean
  defp build_stop_markers(stops, icon, floor_position? \\ false) do
    Enum.map(stops, &build_stop_marker(&1, icon, floor_position?))
  end

  defp build_stop_marker(stop, icon, true) do
    floored_lat = floor_position(stop.latitude)
    floored_lng = floor_position(stop.longitude)
    Marker.new(floored_lat, floored_lng, icon: icon, tooltip: stop.name, size: :tiny)
  end
  defp build_stop_marker(stop, icon, false) do
    Marker.new(stop.latitude, stop.longitude, icon: icon, tooltip: stop.name, size: :tiny)
  end

  @spec floor_position(float) :: float
  defp floor_position(position) do
    Float.floor(position, 4)
  end


  @spec dynamic_map_data(String.t, [String.t], {[Stops.Stop.t], any}, [String.t], map()) :: MapData.t
  def dynamic_map_data(color, map_polylines, {stops, _shapes}, vehicle_polylines, vehicle_tooltips) do
    markers = dynamic_markers(stops, vehicle_tooltips, color)
    paths = dynamic_paths(color, map_polylines, vehicle_polylines)

    {600, 600}
    |> MapData.new
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> MapData.disable_map_type_controls
  end

  defp dynamic_markers(stops, vehicle_tooltips, color) do
    stop_icon = static_url(Site.Endpoint, "/images/map-#{color}-dot-icon.png")
    vehicle_icon = static_url(Site.Endpoint, "/images/map-#{color}-vehicle-icon.png")
    vehicle_markers = vehicle_tooltips |> get_vehicles |> build_vehicle_markers(vehicle_icon)
    build_stop_markers(stops, stop_icon) ++ vehicle_markers
  end

  defp dynamic_paths(color, route_polylines, vehicle_polylines) do
    route_paths = Enum.map(route_polylines, &Path.new(&1, color, 4))
    vehicle_paths = Enum.map(vehicle_polylines, &Path.new(&1, color, 2))
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
  def map_data(route, map_stops, vehicle_polylines, vehicle_tooltips) do
    color = MapHelpers.route_map_color(route)
    map_polylines = map_polylines(map_stops, route)
    static_data = map_img_src(map_stops, map_polylines, route, color)
    dynamic_data = dynamic_map_data(color, map_polylines, map_stops, vehicle_polylines, vehicle_tooltips)
    {static_data, dynamic_data}
  end

  @spec map_polylines({any, [Routes.Shape.t]}, Route.t) :: [String.t]
  defp map_polylines(_, %Routes.Route{type: 4}), do: []
  defp map_polylines({_stops, shapes}, _) do
    shapes
    |> Enum.flat_map(& PolylineHelpers.condense([&1.polyline]))
  end

  @doc "Returns the stops that should be displayed on the map"
  @spec map_stops([RouteStops.t], {[Shape.t], [Shape.t]}, Route.id_t, String.t | nil) :: {[Stops.Stop.t], [Shape.t]}
  def map_stops(branches, {route_shapes, _active_shapes}, "Green", expanded_branch) when not is_nil(expanded_branch) do
    stops = branches |> Enum.filter(& &1.branch == expanded_branch) |> do_map_stops()
    {stops, route_shapes}
  end
  def map_stops(branches, {route_shapes, _active_shapes}, "Green", _expanded) do
    {do_map_stops(branches), route_shapes}
  end
  def map_stops(branches, {_route_shapes, active_shapes}, _route_id, _expanded) do
    {do_map_stops(branches), active_shapes}
  end

  @spec do_map_stops([RouteStops.t]) :: [Stops.Stop.t]
  defp do_map_stops(branches) do
    branches
    |> Enum.flat_map(& &1.stops)
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(& &1.station_info)
  end
end
