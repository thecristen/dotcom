defmodule TripTime do
  @moduledoc """
  Wraps information about a trip time

  * schedule: The schedule for this trip
  * prediction: The prediction for this trip (optional)
  """
  alias Schedules.Schedule
  alias Predictions.Prediction

  @enforce_keys [:schedule]
  defstruct [:schedule, :prediction]
  @type t :: %__MODULE__{
    schedule: Schedule.t,
    prediction: Prediction.t | nil
  }


  @doc """
  Given a list of predictions and a list of schedules, will create
  a list of TripTimes. Predictions and schedules are merged together
  by stop ID to build a TripTime.
  """
  @spec build_times([Prediction.t], [Schedule.t]) :: [TripTime.t]
  def build_times(predictions, schedules) do
    schedule_map = Map.new(schedules, &({&1.stop.id, &1}))
    prediction_map = Map.new(predictions, &({&1.stop_id, &1}))

    Map.keys(schedule_map)
    |> Enum.map(&{Map.get(schedule_map, &1), Map.get(prediction_map, &1)})
    |> Enum.sort_by(&(elem(&1, 0).time))
    |> Enum.map(& %TripTime{schedule: elem(&1, 0), prediction: elem(&1, 1)})
  end
end
