defmodule SiteWeb.StopController.StopMap do
  @moduledoc """
  Module for building map info for Google Maps on stop pages
  """
  alias GoogleMaps.{MapData, MapData.Marker, ViewHelpers}
  alias Phoenix.HTML
  alias SiteWeb.PartialView
  alias Stops.Stop

  @srcset_sizes [
    {140, 60},
    {280, 120},
    {340, 146},
    {400, 172},
    {520, 222}
  ]

  @type grouped_routes_map :: [%{group_name: atom, routes: [map]}]

  @doc """
  Returns a triplet containing a map data object, the image srcset, and the static image url
  """
  @spec map_info(Stop.t(), grouped_routes_map) :: %{
          map_data: MapData.t(),
          map_srcset: String.t(),
          map_url: String.t()
        }
  def map_info(stop, grouped_routes) do
    map_data = build_map_data(stop, grouped_routes, 2, 735, 250)

    %{
      map_data: map_data,
      map_srcset: map_srcset(stop, grouped_routes),
      map_url: map_url(map_data)
    }
  end

  @spec map_srcset(Stop.t(), grouped_routes_map) :: String.t()
  defp map_srcset(stop, routes) do
    @srcset_sizes
    |> GoogleMaps.scale()
    |> Enum.map(&do_map_srcset(&1, stop, routes))
    |> Picture.srcset()
  end

  @spec do_map_srcset({integer, integer, 1 | 2}, Stop.t(), grouped_routes_map) ::
          {String.t(), String.t()}
  defp do_map_srcset({width, height, scale}, stop, routes) do
    size = "#{width * scale}"
    stop_map_src = stop |> build_map_data(routes, scale, width, height) |> map_url()
    {size, stop_map_src}
  end

  @spec map_url(MapData.t()) :: String.t()
  defp map_url(map_data) do
    GoogleMaps.static_map_url(map_data)
  end

  @spec build_map_data(Stop.t(), grouped_routes_map, 1 | 2, integer, integer) :: MapData.t()
  defp build_map_data(stop, routes, scale, width, height) do
    {width, height}
    |> MapData.new(16, scale)
    |> MapData.disable_map_type_controls()
    |> MapData.add_layers(%MapData.Layers{transit: true})
    |> add_stop_marker(stop, routes)
  end

  @spec add_stop_marker(MapData.t(), Stop.t(), grouped_routes_map) :: MapData.t()
  defp add_stop_marker(map_data, stop, routes) do
    marker = build_current_stop_marker(stop, routes)
    MapData.add_marker(map_data, marker)
  end

  @spec build_current_stop_marker(
          Stop.t(),
          grouped_routes_map
        ) :: GoogleMaps.MapData.Marker.t()
  def build_current_stop_marker(stop, routes) do
    Marker.new(
      stop.latitude,
      stop.longitude,
      id: "current-stop",
      icon: ViewHelpers.marker_for_routes([]),
      visible?: !stop.station?,
      size: :large,
      tooltip: tooltip(stop, routes)
    )
  end

  defp tooltip(stop, routes) do
    grouped_routes =
      Enum.map(routes, fn grouped_routes_with_directions ->
        %{
          group_name: grouped_routes_with_directions.group_name,
          routes:
            Enum.map(grouped_routes_with_directions.routes, fn route_with_directions ->
              route_with_directions.route
            end)
        }
      end)

    "_location_card.html"
    |> PartialView.render(%{stop: stop, routes: grouped_routes})
    |> HTML.safe_to_string()
  end
end
