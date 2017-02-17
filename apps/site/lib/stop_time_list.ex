defmodule StopTimeList do
  @moduledoc """
  Responsible for grouping together schedules and predictions based on an origin and destination, in
  a form to be used in the schedule views.
  """

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}

  defstruct [
    times: [],
    showing_all?: false
  ]
  @type t :: %__MODULE__{
    times: [StopTime.t],
    showing_all?: boolean
  }
  @type stop_id :: String.t
  @type schedule_pair :: {Schedule.t, Schedule.t}
  @type schedule_map :: %{Trip.t => %{stop_id => Schedule.t}}
  @type schedule_pair_map :: %{Trip.t => schedule_pair}

  @spec build([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil, StopTime.Filter.filter_flag_t, DateTime.t | nil) :: __MODULE__.t
  def build(schedules, predictions, origin_id, destination_id, filter_flag, current_time) do
    schedules
    |> build_times(predictions, origin_id, destination_id)
    |> from_times(filter_flag, current_time)
  end

  @doc """
  Build a StopTimeList using only predictions. This will also filter out predictions that are
  missing departure_predictions. Limits to 5 predictions at most.
  """
  @spec build_predictions_only([Prediction.t], String.t | nil, String.t | nil) :: __MODULE__.t
  def build_predictions_only(predictions, origin_id, destination_id) do
    []
    |> build_times(predictions, origin_id, destination_id)
    |> Enum.filter(&StopTime.has_departure_prediction?/1)
    |> Enum.take(5)
    |> from_times(:keep_all, nil)
  end

  @spec build_times([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil) :: [StopTime.t]
  defp build_times(schedules, predictions, origin_id, destination_id) when is_binary(origin_id) and is_binary(destination_id) do
    group_trips(
      schedules,
      predictions,
      origin_id,
      destination_id,
      &build_schedule_pair_map/2,
      &build_stop_time(&1, &2, &3, origin_id, destination_id)
    )
  end
  defp build_times(schedules, predictions, origin_id, nil) when is_binary(origin_id) do
    group_trips(
      schedules,
      predictions,
      origin_id,
      nil,
      &build_schedule_map/2,
      &predicted_departures(&1, &2, &3, origin_id)
    )
  end
  defp build_times(_schedules, _predictions, _origin_id, _destination_id), do: []

  # Creates a StopTimeList object from a list of times and the showing_all? flag
  @spec from_times([StopTime.t], StopTime.Filter.filter_flag_t, DateTime.t | nil) :: __MODULE__.t
  defp from_times(stop_times, filter_flag, current_time) do
    %__MODULE__{
      times:
        stop_times
        |> StopTime.Filter.filter(filter_flag, current_time)
        |> StopTime.Filter.sort
        |> StopTime.Filter.limit(filter_flag),
      showing_all?: filter_flag == :keep_all
    }
  end

  defp group_trips(schedules, predictions, origin_id, destination_id, build_schedule_map_fn, trip_mapper_fn) do
    prediction_map = PredictedSchedule.Group.build_prediction_map(predictions, schedules, origin_id, destination_id)
    schedule_map = Enum.reduce(schedules, %{}, build_schedule_map_fn)

    schedule_map
    |> get_trips(prediction_map)
    |> Enum.map(&(trip_mapper_fn.(&1, schedule_map, prediction_map)))
  end

  @spec build_stop_time(Trip.t | nil, schedule_pair_map, PredictedSchedule.Group.prediction_map_t, stop_id, stop_id) :: StopTime.t
  defp build_stop_time(trip, schedule_map, prediction_map, origin_id, dest) do
    departure_prediction = prediction_map[trip][origin_id]
    arrival_prediction = prediction_map[trip][dest]
    case Map.get(schedule_map, trip) do
      {departure, arrival} -> %StopTime{
                              departure: %PredictedSchedule{schedule: departure, prediction: departure_prediction},
                              arrival: %PredictedSchedule{schedule: arrival, prediction: arrival_prediction},
                              trip: trip
                          }
      nil -> %StopTime{
             departure: %PredictedSchedule{schedule: nil, prediction: departure_prediction},
             arrival: %PredictedSchedule{schedule: nil, prediction: arrival_prediction},
             trip: trip
         }
    end
  end

  @spec predicted_departures(Trip.t | nil, schedule_map, PredictedSchedule.Group.prediction_map_t, stop_id) :: StopTime.t
  defp predicted_departures(trip, schedule_map, prediction_map, origin_id) do
    departure_schedule = schedule_map[trip][origin_id]
    departure_prediction = prediction_map[trip][origin_id]
    %StopTime{
      departure: %PredictedSchedule{schedule: departure_schedule, prediction: departure_prediction},
      arrival: nil,
      trip: trip
    }
  end

  @spec get_trips(%{Trip.t => any}, PredictedSchedule.Group.prediction_map_t) :: [Trip.t]
  defp get_trips(schedule_map, prediction_map) do
    Map.keys(prediction_map)
    |> Enum.concat(Map.keys(schedule_map))
    |> Enum.uniq
  end

  @spec build_schedule_pair_map({Schedule.t, Schedule.t}, schedule_pair_map) :: schedule_pair_map
  defp build_schedule_pair_map({departure, arrival}, schedule_pair_map) do
    Map.put(schedule_pair_map, departure.trip, {departure, arrival})
  end

  @spec build_schedule_map(Schedule.t, schedule_map) :: schedule_map
  defp build_schedule_map(schedule, schedule_map) do
    updater = fn(trip_map) -> Map.merge(trip_map, %{schedule.stop.id => schedule}) end
    Map.update(schedule_map, schedule.trip, %{schedule.stop.id => schedule}, updater)
  end
end
