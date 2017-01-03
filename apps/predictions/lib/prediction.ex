defmodule Predictions.Prediction do
  defstruct [:trip_id, :stop_id, :route_id, :direction_id, :time, :relationship, :track, :status]
  @type t :: %__MODULE__{
    trip_id: String.t,
    stop_id: String.t,
    route_id: String.t,
    direction_id: 0 | 1,
    time: DateTime.t,
    relationship: nil | :added | :unscheduled | :canceled | :skipped | :no_data,
    track: String.t | nil,
    status: String.t | nil
  }
end
