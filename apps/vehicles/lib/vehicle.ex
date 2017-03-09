defmodule Vehicles.Vehicle do
  defstruct [:id, :route_id, :trip_id, :stop_id, :stop_name, :direction_id, :status]

  @type status :: :in_transit | :stopped | :incoming

  @type t :: %__MODULE__{
    id: String.t,
    route_id: String.t,
    trip_id: String.t | nil,
    stop_id: String.t,
    stop_name: String.t | nil,
    direction_id: 0 | 1,
    status: status
  }
end
