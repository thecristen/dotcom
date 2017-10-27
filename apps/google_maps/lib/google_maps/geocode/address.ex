defmodule GoogleMaps.Geocode.Address do
  @type t :: %__MODULE__{
    formatted: String.t,
    latitude: float,
    longitude: float
  }
  defstruct [
    formatted: "",
    latitude: 0.0,
    longitude: 0.0
  ]

  defimpl Util.Position do
    def latitude(address), do: address.latitude
    def longitude(address), do: address.longitude
  end
end
