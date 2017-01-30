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
  The given predictions and schedules will be merged together according to
  stop_id to create PredictedSchedules. The final result is a sorted list of
  PredictedSchedules where the `schedule` and `prediction` share a trip_id.
  Either the `schedule` or `prediction` may be nil, but not both.
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

  @doc """
  Determines if the given PredictedSchedule has a prediction
  """
  @spec has_prediction?(PredictedSchedule.t) :: boolean
  def has_prediction?(%PredictedSchedule{prediction: nil}), do: false
  def has_prediction?(_), do: true

  # Returns unique list of all stop_id's from given schedules and predictions
  @spec stop_ids(%{String.t => Schedule.t}, %{String.t => Prediction.t}) :: [String.t]
  defp stop_ids(schedule_map, prediction_map) do
    schedule_map
    |> Map.keys()
    |> Enum.concat(Map.keys(prediction_map))
    |> Enum.uniq
  end

  @doc """
  Returns the time difference between a schedule and prediction. If either is nil, returns 0.
  """
  @spec delay(PredictedSchedule.t | nil) :: integer
  def delay(nil), do: 0
  def delay(%PredictedSchedule{schedule: schedule, prediction: prediction}) when is_nil(schedule) or is_nil(prediction), do: 0
  def delay(%PredictedSchedule{schedule: schedule, prediction: prediction}) do
    Timex.diff(prediction.time, schedule.time, :minutes)
  end

  @doc """
  Returns a message containing the maximum delay between scheduled and predicted times for an arrival
  and departure, or the empty string if there's no delay.
  """
  @spec display_delay(PredictedSchedule.t, PredictedSchedule.t) :: iodata
  def display_delay(departure, arrival) do
    case Enum.max([delay(departure), delay(arrival)]) do
      delay when delay > 0 -> [
        "Delayed ",
        Integer.to_string(delay),
        " ",
        Inflex.inflect("minute", delay)
      ]
      _ -> ""
    end
  end

  @spec sort_predicted_schedules(PredictedSchedule.t) :: {integer, DateTime.t}
  defp sort_predicted_schedules(%PredictedSchedule{schedule: nil, prediction: prediction}), do: {0, prediction.time}
  defp sort_predicted_schedules(%PredictedSchedule{schedule: schedule}), do: {1, schedule.time}
end
