defmodule GoogleMaps.MapData.Marker do
  @moduledoc """
  Represents a google map marker. Markers with `visible?` as
  false will not be shown on the map, but will still be used in
  centering the map.
  """

  @type size :: :tiny | :mid | :small
  @default_opts [icon: nil, size: :mid, visible?: true]

  defstruct [
    latitude: 0.0,
    longitude: 0.0,
    icon: nil,
    visible?: true,
    size: :mid
  ]

  @type t :: %__MODULE__{
    latitude: float,
    longitude: float,
    icon: String.t | nil,
    visible?: boolean,
    size: size
  }

  def new(latitude, longitude, opts \\ []) do
    map_options = Keyword.merge(@default_opts, opts)
    %__MODULE__{
      latitude: latitude,
      longitude: longitude,
      icon: map_options[:icon],
      visible?: map_options[:visible?],
      size: map_options[:size]
    }
  end

  @doc "Formats a single marker for a static map"
  @spec format_static_marker(t) :: String.t
  def format_static_marker(marker) do
    Enum.join([marker.latitude, marker.longitude], ",")
  end
end
