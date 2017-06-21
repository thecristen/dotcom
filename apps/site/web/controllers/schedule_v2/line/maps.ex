defmodule Site.ScheduleV2Controller.Line.Maps do
  alias GoogleMaps.MapData
  alias GoogleMaps.MapData.{Path, Marker}

  @moduledoc """
  Handles Map information for the line controller
  """

  import Site.Router.Helpers

  def map_img_src(_, _, %Routes.Route{type: 4}) do
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end
  def map_img_src({stops, _shapes}, polylines, route) do
    icon = map_stop_icon_path(route.type, route.id)
    markers = build_stop_markers(stops, icon, true)
    paths = Enum.map(polylines, &build_path(&1, route))

    {600, 600}
    |> MapData.new
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> GoogleMaps.static_map_url()
  end

  defp build_path(polyline, route) do
    color = route.type |> map_color(route.id) |> format_color()
    Path.new(polyline, color)
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

  defp format_color(color), do: "0x" <> color <> "FF"

  @spec floor_position(float) :: float
  defp floor_position(position) do
    Float.floor(position, 4)
  end

  @spec map_stop_icon_path(0..4, String.t) :: String.t
  defp map_stop_icon_path(type, id) do
    static_url(Site.Endpoint, "/images/map-#{map_color(type, id)}-dot-icon.png")
  end

  @spec map_color(0..4, String.t) :: String.t
  def map_color(3, _id), do: "FFCE0C"
  def map_color(2, _id), do: "A00A78"
  def map_color(_type, "Blue"), do: "0064C8"
  def map_color(_type, "Red"), do: "FF1428"
  def map_color(_type, "Mattapan"), do: "FF1428"
  def map_color(_type, "Orange"), do: "FF8200"
  def map_color(_type, "Green"), do: "428608"
  def map_color(_type, _id), do: "0064C8"

  @spec dynamic_map_data(String.t, [String.t], [String.t], {[Stops.Stop.t], any}, map()) :: MapData.t
  def dynamic_map_data(color, route_polylines, vehicle_polylines, {stops, _shapes}, vehicle_tooltips) do
    markers = dynamic_markers(stops, vehicle_tooltips, color)
    paths = dynamic_paths(color, route_polylines, vehicle_polylines)

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
end
