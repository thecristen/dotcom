defmodule Predictions.Prediction do
  defstruct [:id, :trip, :stop, :route, :direction_id, :time, :schedule_relationship, :track, :status, :departing?]
  @type id_t :: String.t
  @type schedule_relationship :: nil | :added | :unscheduled | :cancelled | :skipped | :no_data
  @type t :: %__MODULE__{
    id: id_t,
    trip: Schedules.Trip.t | nil,
    stop: Schedules.Stop.t,
    route: Routes.Route.t,
    direction_id: 0 | 1,
    time: DateTime.t | nil,
    schedule_relationship: schedule_relationship,
    track: String.t | nil,
    status: String.t | nil,
    departing?: boolean
  }
end
