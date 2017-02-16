defmodule Predictions.Prediction do
  defstruct [:trip, :stop, :route, :direction_id, :time, :schedule_relationship, :track, :status, :departing?]
  @type t :: %__MODULE__{
    trip: Schedules.Trip.t | nil,
    stop: Schedules.Stop.t,
    route: Routes.Route.t,
    direction_id: 0 | 1,
    time: DateTime.t,
    schedule_relationship: nil | :added | :unscheduled | :canceled | :skipped | :no_data,
    track: String.t | nil,
    status: String.t | nil,
    departing?: boolean
  }
end
