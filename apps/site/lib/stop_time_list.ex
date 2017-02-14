defmodule StopTimeList do
  @moduledoc """
  Responsible for grouping together schedules and predictions based on an origin and destination, in
  a form to be used in the schedule views.
  """

  alias Predictions.Prediction
  alias Schedules.{Schedule, Stop, Trip}

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
  @type prediction_map :: %{Trip.t => %{stop_id => Prediction.t}}

  @type filter_flag :: :keep_all | :last_trip_and_upcoming | :predictions_then_schedules

  @spec build([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil, filter_flag, DateTime.t | nil) :: __MODULE__.t
  def build(schedules, predictions, origin, destination, filter_flag, current_time) do
    filtered_predictions = filtered_predictions(predictions, schedules, destination)

    schedules
    |> build_times(filtered_predictions, origin, destination)
    |> from_times(filter_flag, current_time)
  end

  @doc """
  Build a StopTimeList using only predictions. This will also filter out predictions that are
  missing departure_predictions. Limits to 5 predictions at most.
  """
  @spec build_predictions_only([Schedule.t | schedule_pair | nil], [Prediction.t], String.t | nil, String.t | nil) :: __MODULE__.t
  def build_predictions_only(schedules, predictions, origin, destination) do
    filtered_predictions = filtered_predictions(predictions, schedules, destination)

    []
    |> build_times(filtered_predictions, origin, destination)
    |> Enum.filter(&StopTime.has_departure_prediction?/1)
    |> Enum.take(5)
    |> from_times(:keep_all, nil)
  end

  @spec build_times([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil) :: [StopTime.t]
  defp build_times(schedules, predictions, origin, destination) when is_binary(origin) and is_binary(destination) do
    group_trips(
      schedules,
      predictions,
      &build_schedule_pair_map/2,
      &build_stop_time(&1, &2, &3, origin, destination)
    )
  end
  defp build_times(schedules, predictions, origin, nil) when is_binary(origin) do
    group_trips(
      schedules,
      predictions,
      &build_schedule_map/2,
      &predicted_departures(&1, &2, &3, origin)
    )
  end
  defp build_times(_schedules, _predictions, _origin, _destination), do: []

  # Creates a StopTimeList object from a list of times and the showing_all? flag
  @spec from_times([StopTime.t], filter_flag, DateTime.t | nil) :: __MODULE__.t
  defp from_times(stop_times, filter_flag, current_time) do
    %__MODULE__{
      times:
        stop_times
        |> StopTimeFilter.filter(filter_flag, current_time)
        |> StopTimeFilter.sort
        |> StopTimeFilter.limit(filter_flag),
      showing_all?: filter_flag == :keep_all
    }
  end

  defp group_trips(schedules, predictions, build_schedule_map_fn, trip_mapper_fn) do
    prediction_map = Enum.reduce(predictions, %{}, &build_prediction_map/2)
    schedule_map = Enum.reduce(schedules, %{}, build_schedule_map_fn)

    schedule_map
    |> get_trips(predictions)
    |> Enum.map(&(trip_mapper_fn.(&1, schedule_map, prediction_map)))
  end

  @spec build_stop_time(Trip.t | nil, schedule_pair_map, prediction_map, stop_id, stop_id) :: StopTime.t
  defp build_stop_time(trip, schedule_map, prediction_map, origin, dest) do
    departure_prediction = prediction_map[trip][origin]
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

  @spec predicted_departures(Trip.t | nil, schedule_map, prediction_map, stop_id) :: StopTime.t
  defp predicted_departures(trip, schedule_map, prediction_map, origin) do
    departure_schedule = schedule_map[trip][origin]
    departure_prediction = prediction_map[trip][origin]
    %StopTime{
      departure: %PredictedSchedule{schedule: departure_schedule, prediction: departure_prediction},
      arrival: nil,
      trip: trip
    }
  end

  @spec get_trips(%{Trip.t => any}, [Prediction.t]) :: [Trip.t]
  defp get_trips(schedule_map, predictions) do
    predictions
    |> Enum.map(& &1.trip)
    |> Enum.concat(Map.keys(schedule_map))
    |> Enum.uniq
  end

  @spec build_schedule_pair_map({Schedule.t, Schedule.t}, schedule_pair_map) :: schedule_pair_map
  defp build_schedule_pair_map({departure, arrival}, schedule_pair_map) do
    Map.put(schedule_pair_map, departure.trip, {departure, arrival})
  end

  @spec build_prediction_map(Prediction.t, prediction_map) :: prediction_map
  defp build_prediction_map(prediction, prediction_map) do
    updater = fn(trip_map) -> Map.merge(trip_map, %{prediction.stop_id => prediction}) end
    Map.update(prediction_map, prediction.trip, %{prediction.stop_id => prediction}, updater)
  end

  @spec build_schedule_map(Schedule.t, schedule_map) :: schedule_map
  defp build_schedule_map(schedule, schedule_map) do
    updater = fn(trip_map) -> Map.merge(trip_map, %{schedule.stop.id => schedule}) end
    Map.update(schedule_map, schedule.trip, %{schedule.stop.id => schedule}, updater)
  end

  # Remove any predictions for trips that don't go through the
  # destination stop, by checking the list of schedules to ensure that
  # there's an O/D pair for each prediction's trip.
  defp filtered_predictions(predictions, _schedules, nil), do: predictions
  defp filtered_predictions(predictions, nil, _destination), do: predictions
  defp filtered_predictions(predictions, schedules, destination) do
    schedule_pair_trip_ids = MapSet.new(
      schedules,
      fn
        {_, %Schedule{trip: %Trip{id: trip_id}, stop: %Stop{id: ^destination}}} -> trip_id
        _ -> nil
      end
    )

    Enum.filter(
      predictions,
      fn
        %Prediction{trip: nil} -> false
        %Prediction{stop_id: ^destination} -> true
        %Prediction{trip: %Trip{id: trip_id}} -> trip_id in schedule_pair_trip_ids
      end
    )
  end
end
