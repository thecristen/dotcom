defmodule PredictedSchedule do
  @moduledoc """
  Wraps information about a Predicted Schedule

  * schedule: The schedule for this trip (optional)
  * prediction: The prediction for this trip (optional)
  """
  alias Schedules.{Schedule, Trip}
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
  def has_prediction?(%PredictedSchedule{}), do: true

  @doc """
  Returns a time tuple for the given PredictedSchedule. The return value is a two pair,
  consisting of an atom, :prediction or :scheduled, which represents if the returned time
  is predicted or scheduled, and the time. **Schedule Times are preferred**.
  """
  @spec time(PredictedSchedule.t) :: {:prediction | :schedule, DateTime.t}
  def time(%PredictedSchedule{schedule: nil, prediction: prediction}), do: {:prediction, prediction.time}
  def time(%PredictedSchedule{schedule: schedule}), do: {:schedule, schedule.time}

  @doc """
  Returns a time value for the given PredictedSchedule. Returned value can be either a scheduled time
  for a prediction time. **Scheduled Times are preferred**
  """
  @spec time!(PredictedSchedule.t) :: DateTime.t
  def time!(predicted_schedule), do: elem(time(predicted_schedule), 1)

  @doc """

  Given a Predicted schedule and an order of keys, call the given function
  with the prediction/schedule that's not nil.  If all are nil, then return
  the default value.

  """
  @spec map_optional(PredictedSchedule.t, [:schedule | :prediction], any, ((Schedule.t | Prediction.t) -> any)) :: any
  def map_optional(predicted_schedule, ordering, default \\ nil, func)
  def map_optional(nil, _ordering, default, _func) do
    default
  end
  def map_optional(_predicted_schedule, [], default, _func) do
    default
  end
  def map_optional(predicted_schedule, [:schedule | rest], default, func) do
    case predicted_schedule.schedule do
      nil -> map_optional(predicted_schedule, rest, default, func)
      schedule -> func.(schedule)
    end
  end
  def map_optional(predicted_schedule, [:prediction | rest], default, func) do
    case predicted_schedule.prediction do
      nil -> map_optional(predicted_schedule, rest, default, func)
      prediction -> func.(prediction)
    end
  end
  @doc """
  Returns the trip associated with this Predicted Schedule
  """
  @spec trip(PredictedSchedule.t) :: Trip
  def trip(%PredictedSchedule{schedule: nil, prediction: prediction}) do
    prediction.trip
  end
  def trip(%PredictedSchedule{schedule: schedule}) do
    schedule.trip
  end

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
