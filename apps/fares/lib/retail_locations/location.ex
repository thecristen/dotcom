defmodule Fares.RetailLocations.Location do
  defstruct [:agent,
             :city,
             :latitude,
             :longitude,
             :location,
            ]

  @type t :: %__MODULE__{
    agent: String.t,
    city: String.t,
    latitude: float,
    longitude: float,
    location: String.t,
  }

  defimpl Util.Position do
    def latitude(%@for{latitude: latitude}), do: latitude
    def longitude(%@for{longitude: longitude}), do: longitude
  end
end
