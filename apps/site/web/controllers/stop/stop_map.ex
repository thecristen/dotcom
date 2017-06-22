defmodule Site.StopController.StopMap do
  alias Stops.Stop
  alias GoogleMaps.{MapData, MapData.Marker}

  @srcset_sizes [
    {140, 60},
    {280, 120},
    {340, 146},
    {400, 172},
    {520, 222}
  ]

  @doc """
  Returns a triplet containing a map data object, the image srcset, and the static image url
  """
  @spec map_info(Stop.t) :: {MapData.t, String.t, String.t}
  def map_info(stop) do
    map_data = build_map_data(stop, 2, 735, 250)
    {map_data, map_srcset(stop), map_url(map_data)}
  end

  @spec map_srcset(Stop.t) :: String.t
  defp map_srcset(stop) do
    @srcset_sizes
    |> GoogleMaps.scale
    |> Enum.map(&do_map_srcset(&1, stop))
    |> Picture.srcset
  end

  @spec do_map_srcset({integer, integer, 1 | 2}, Stop.t) :: {String.t, String.t}
  defp do_map_srcset({width, height, scale}, stop) do
    size = "#{width * scale}"
    stop_map_src = stop |> build_map_data(scale, width, height) |> map_url()
    {size, stop_map_src}
  end

  @spec map_url(MapData.t) :: String.t
  defp map_url(map_data) do
    GoogleMaps.static_map_url(map_data)
  end

  @spec build_map_data(Stop.t, 1 | 2, integer, integer) :: MapData.t
  defp build_map_data(stop, scale, width, height) do
    {width, height}
    |> MapData.new(16, scale)
    |> add_stop_marker(stop)
  end

  @spec add_stop_marker(MapData.t, Stop.t) :: MapData.t
  defp add_stop_marker(map_data, stop) do
    marker = Marker.new(stop.latitude, stop.longitude, visible?: !stop.station?)
    MapData.add_marker(map_data, marker)
  end
end
