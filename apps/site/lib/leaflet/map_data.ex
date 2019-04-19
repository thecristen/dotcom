defmodule Leaflet.MapData do
  @moduledoc """
  Represents leaflet map data.
  """
  alias GoogleMaps.MapData, as: GoogleMapData
  alias GoogleMaps.MapData.Marker, as: GoogleMapsMarker
  alias Leaflet.MapData.Marker

  @type lat_lng :: %{latitude: float, longitude: float}

  defstruct default_center: %{latitude: 42.360718, longitude: -71.05891},
            markers: [],
            width: 0,
            height: 0,
            zoom: nil,
            tile_server_url: ""

  @type t :: %__MODULE__{
          default_center: lat_lng,
          markers: [Marker.t()],
          width: integer,
          height: integer,
          zoom: integer | nil,
          tile_server_url: String.t()
        }

  @spec new({integer, integer}, integer | nil) :: t
  def new({width, height}, zoom \\ nil) do
    %__MODULE__{
      width: width,
      height: height,
      zoom: zoom
    }
  end

  @spec add_marker(t, Marker.t()) :: t
  def add_marker(map_data, marker) do
    %{map_data | markers: [marker | map_data.markers]}
  end

  def to_google_map_data(%{
        default_center: default_center,
        width: width,
        height: height,
        zoom: zoom,
        markers: markers
      }) do
    %GoogleMapData{
      default_center: default_center,
      width: width,
      height: height,
      zoom: zoom,
      scale: 2,
      markers:
        Enum.map(markers, fn %{latitude: latitude, longitude: longitude} ->
          %GoogleMapsMarker{
            longitude: longitude,
            latitude: latitude,
            visible?: false
          }
        end)
    }
  end
end
