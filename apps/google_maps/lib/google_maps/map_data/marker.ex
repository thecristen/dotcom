defmodule GoogleMaps.MapData.Marker do
  @moduledoc """
  Represents a google map marker. Markers with `visible?` as
  false will not be shown on the map, but will still be used in
  centering the map.
  """

  @type size :: :tiny | :mid | :small

  defstruct [
    latitude: "",
    longitude: "",
    icon: nil,
    tooltip: "",
    visible?: true,
    size: :mid
  ]

  @type t :: %__MODULE__{
    latitude: float,
    longitude: float,
    icon: String.t | nil,
    tooltip: String.t,
    visible?: boolean,
    size: size
  }

  @doc "Formats a single marker for a static map"
  @spec format_static_marker(t) :: String.t
  def format_static_marker(marker) do
    Enum.join([marker.latitude, marker.longitude], ",")
  end
end
