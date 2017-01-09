defmodule Predictions.Prediction do
  defstruct [:trip, :stop_id, :route_id, :direction_id, :time, :schedule_relationship, :track, :status, :departure_time, :arrival_time]
  @type t :: %__MODULE__{
    trip: Schedules.Trip.t | nil,
    stop_id: String.t,
    route_id: String.t,
    direction_id: 0 | 1,
    time: DateTime.t,
    schedule_relationship: nil | :added | :unscheduled | :canceled | :skipped | :no_data,
    track: String.t | nil,
    status: String.t | nil,
    departure_time: DateTime.t | nil,
    arrival_time: DateTime.t | nil
  }
end
