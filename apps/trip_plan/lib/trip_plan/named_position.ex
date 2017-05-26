defmodule TripPlan.NamedPosition do
  defstruct [
    name: "",
    stop_id: nil,
    latitude: 0,
    longitude: 0
  ]
  @type t :: %__MODULE__{
    name: String.t,
    stop_id: Stops.Stop.id_t | nil,
    latitude: float,
    longitude: float
  }

  defimpl Stops.Position do
    def latitude(%{latitude: latitude}), do: latitude
    def longitude(%{longitude: longitude}), do: longitude
  end
end
