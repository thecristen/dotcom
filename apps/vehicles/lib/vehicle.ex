defmodule Vehicles.Vehicle do
  defstruct [:id, :route_id, :trip_id, :stop_id, :direction_id, :longitude, :latitude, :status]

  @type status :: :in_transit | :stopped | :incoming

  @type t :: %__MODULE__{
    id: String.t,
    route_id: String.t | nil,
    trip_id: String.t | nil,
    stop_id: String.t | nil,
    direction_id: 0 | 1,
    longitude: float,
    latitude: float,
    status: status
  }
end
