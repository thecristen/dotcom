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
  @type schedule_pair :: PredictedSchedule.Group.schedule_pair_t
  @type map_key_t :: PredictedSchedule.Group.map_key_t
  @type schedule_map :: %{map_key_t => %{stop_id => Schedule.t}}
  @type schedule_pair_map :: %{map_key_t => schedule_pair}

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
  @spec build_predictions_only([Schedule.t], [Prediction.t], String.t | nil, String.t | nil) :: __MODULE__.t
  def build_predictions_only(schedules, predictions, origin_id, destination_id) do
    stop_time = schedules
    |> build_times(predictions, origin_id, destination_id)
    |> Enum.filter(&StopTime.has_departure_prediction?/1)
    |> from_times(:keep_all, nil)
    %{stop_time | times: Enum.take(stop_time.times, 5)}
  end

  @spec build_times([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil) :: [StopTime.t]
  defp build_times(schedules, predictions, origin_id, destination_id) when is_binary(origin_id) and is_binary(destination_id) do
    stop_times = group_trips(
      schedules,
      predictions,
      origin_id,
      destination_id,
      &build_schedule_pair_map/2,
      &build_stop_time(&1, &2, &3, origin_id, destination_id)
    )
    Enum.reject(stop_times, &Timex.after?(StopTime.departure_time(&1), StopTime.arrival_time(&1)))
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
    filtered_times = stop_times
    |> StopTime.Filter.filter(filter_flag, current_time)
    |> StopTime.Filter.sort
    |> StopTime.Filter.limit(filter_flag)

    %__MODULE__{
      times: filtered_times,
      showing_all?: length(filtered_times) == length(stop_times)
    }
  end

  defp group_trips(schedules, predictions, origin_id, destination_id, build_schedule_map_fn, trip_mapper_fn) do
    prediction_map = PredictedSchedule.Group.build_prediction_map(predictions, schedules, origin_id, destination_id)
    schedule_map = Enum.reduce(schedules, %{}, build_schedule_map_fn)

    schedule_map
    |> get_trips(prediction_map)
    |> Enum.map(&(trip_mapper_fn.(&1, schedule_map, prediction_map)))
  end

  @spec build_stop_time(map_key_t, schedule_pair_map, PredictedSchedule.Group.prediction_map_t, stop_id, stop_id) :: StopTime.t
  defp build_stop_time(key, schedule_map, prediction_map, origin_id, dest) do
    departure_prediction = prediction_map[key][origin_id]
    arrival_prediction = prediction_map[key][dest]
    case Map.get(schedule_map, key) do
      {departure, arrival} ->
        trip = first_trip([departure_prediction, departure, arrival_prediction, arrival])

        %StopTime{
          departure: %PredictedSchedule{schedule: departure, prediction: departure_prediction},
          arrival: %PredictedSchedule{schedule: arrival, prediction: arrival_prediction},
          trip: trip
        }
      nil ->
        trip = first_trip([departure_prediction, arrival_prediction])
        %StopTime{
          departure: %PredictedSchedule{schedule: nil, prediction: departure_prediction},
          arrival: %PredictedSchedule{schedule: nil, prediction: arrival_prediction},
          trip: trip
        }
    end
  end

  @spec predicted_departures(map_key_t, schedule_map, PredictedSchedule.Group.prediction_map_t, stop_id) :: StopTime.t
  defp predicted_departures(key, schedule_map, prediction_map, origin_id) do
    departure_schedule = schedule_map[key][origin_id]
    departure_prediction = prediction_map[key][origin_id]
    %StopTime{
      departure: %PredictedSchedule{schedule: departure_schedule, prediction: departure_prediction},
      arrival: nil,
      trip: first_trip([departure_prediction, departure_schedule])
    }
  end

  @spec get_trips(schedule_pair_map, PredictedSchedule.Group.prediction_map_t) :: [map_key_t]
  defp get_trips(schedule_map, prediction_map) do
    [prediction_map, schedule_map]
    |> Enum.map(&Map.keys/1)
    |> Enum.concat
    |> Enum.uniq
  end

  @spec build_schedule_pair_map({Schedule.t, Schedule.t}, schedule_pair_map) :: schedule_pair_map
  defp build_schedule_pair_map({departure, arrival}, schedule_pair_map) do
    key = departure.trip
    Map.put(schedule_pair_map, key, {departure, arrival})
  end

  @spec build_schedule_map(Schedule.t, schedule_map) :: schedule_map
  defp build_schedule_map(schedule, schedule_map) do
    key = schedule.trip
    updater = fn(trip_map) -> Map.merge(trip_map, %{schedule.stop.id => schedule}) end
    Map.update(schedule_map, key, %{schedule.stop.id => schedule}, updater)
  end

  @spec first_trip([Schedule.t | Prediction.t | nil]) :: Trip.t | nil
  defp first_trip(list_with_trips) do
    list_with_trips
    |> Enum.reject(&is_nil/1)
    |> List.first
    |> Map.get(:trip)
  end
end
