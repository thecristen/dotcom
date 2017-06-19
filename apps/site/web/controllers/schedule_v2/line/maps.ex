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
    markers = build_markers(stops, route)
    paths = Enum.map(polylines, &build_path(&1, route))

    600
    |> MapData.new(600)
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> GoogleMaps.static_map_url()
  end

  defp build_path(polyline, route) do
    color = route.type |> map_color(route.id) |> format_color()
    Path.new(polyline, color)
  end

  defp build_markers(stops, %Routes.Route{type: type, id: id}) do
    icon = map_stop_icon_path(type, id)
    Enum.map(stops, &build_marker(&1, icon))
  end

  defp build_marker(stop, icon) do
    Marker.new(floor_position(stop.latitude), floor_position(stop.longitude), icon: icon)
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
end
