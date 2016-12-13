defmodule Predictions.Prediction do
  defstruct [:trip_id, :stop_id, :route_id, :direction_id, :time, :track, :status]
  @type t :: %__MODULE__{
    trip_id: String.t,
    stop_id: String.t,
    route_id: String.t,
    direction_id: 0 | 1,
    time: DateTime.t,
    track: String.t | nil,
    status: String.t | nil
  }
end
