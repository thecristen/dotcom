defmodule PredictedSchedule do
  @moduledoc """
  Wraps information about a Predicted Schedule

  * schedule: The schedule for this trip (optional)
  * prediction: The prediction for this trip (optional)
  """
  alias Schedules.Schedule
  alias Predictions.Prediction

  defstruct [
    schedule: nil,
    prediction: nil
  ]
  @type t :: %__MODULE__{
    schedule: Schedule.t | nil,
    prediction: Prediction.t | nil
  }

  @doc """
  Given a list of predictions and a list of schedules, will create
  a list of PredictedSchedules. Predictions and schedules are merged together
  by stop ID to build a TripTime.
  """
  @spec group_by_trip([Prediction.t], [Schedule.t]) :: [PredictedSchedule.t]
  def group_by_trip(predictions, schedules) do
    schedule_map = Map.new(schedules, &({&1.stop.id, &1}))
    prediction_map = Map.new(predictions, &({&1.stop_id, &1}))

    schedule_map
    |> stop_ids(prediction_map)
    |> Enum.map(&{Map.get(schedule_map, &1), Map.get(prediction_map, &1)})
    |> Enum.map(& %PredictedSchedule{schedule: elem(&1, 0), prediction: elem(&1, 1)})
    |> Enum.sort_by(&sort_predicted_schedules/1)
  end

  @doc """
  Returns the stop id for a given PredictedSchedule
  """
  @spec stop_id(PredictedSchedule.t) :: String.t
  def stop_id(%{schedule: %Schedule{stop: stop}}), do: stop.id
  def stop_id(%{prediction: %Prediction{stop_id: stop_id}}), do: stop_id

  # Returns unique list of all stop_id's from given schedules and predictions
  @spec stop_ids(%{String.t => Schedule.t}, %{String.t => Prediction.t}) :: [String.t]
  defp stop_ids(schedule_map, prediction_map) do
    schedule_map
    |> Map.keys()
    |> Enum.concat(Map.keys(prediction_map))
    |> Enum.uniq
  end

  @spec sort_predicted_schedules(PredictedSchedule.t) :: {integer, DateTime.t}
  defp sort_predicted_schedules(%PredictedSchedule{schedule: nil, prediction: prediction}), do: {0, prediction.time}
  defp sort_predicted_schedules(%PredictedSchedule{schedule: schedule}), do: {1, schedule.time}

end
