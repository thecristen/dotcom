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
    times: [__MODULE__.StopTime.t],
    showing_all?: boolean
  }

  defmodule StopTime do
    defstruct [:departure, :arrival, :trip]
    @type t :: %__MODULE__{
      departure: predicted_schedule,
      arrival: predicted_schedule | nil,
      trip: Trip.t
    }
    @type predicted_schedule :: {Schedule.t | nil, Prediction.t | nil}
  end

  @spec build([Schedules.Schedule.t], [Predictions.Prediction.t], String.t | nil, String.t | nil, boolean) :: __MODULE__.t
  def build(schedules, predictions, origin, destination, showing_all?)
  def build(schedules, predictions, origin, destination, showing_all?) when is_binary(origin) and is_binary(destination) do
    times = group_trips(
      schedules,
      predictions,
      &build_schedule_pair_map/2,
      &predicted_schedule_pairs(&1, &2, &3, origin, destination)
    )
    %__MODULE__{
      times: limit_trips(times, showing_all?),
      showing_all?: showing_all?
    }
  end
  def build(schedules, predictions, origin, nil, showing_all?) when is_binary(origin) do
    times = group_trips(
      schedules,
      predictions,
      &build_schedule_map/2,
      &predicted_departures(&1, &2, &3, origin)
    )
    %__MODULE__{
      times: limit_trips(times, showing_all?),
      showing_all?: showing_all?
    }
  end
  def build(_schedules, _predictions, _origin, _destination, showing_all?) do
    %__MODULE__{times: [], showing_all?: showing_all?}
  end

  defp group_trips(schedules, predictions, build_schedule_map_fn, trip_mapper_fn) do
    prediction_map = Enum.reduce(predictions, %{}, &build_prediction_map/2)
    schedule_map = Enum.reduce(schedules, %{}, build_schedule_map_fn)

    schedule_map
    |> get_trips(predictions)
    |> Enum.map(&(trip_mapper_fn.(&1, schedule_map, prediction_map)))
    |> Enum.sort_by(&prediction_sorter/1)
    |> remove_first_scheduled
  end

  # Handle cases where we have a scheduled departure and then a
  # prediction which occurs later. If this happens, remove the
  # scheduled departure and just show the prediction.
  @spec remove_first_scheduled([StopTime.t]) :: [StopTime.t]
  defp remove_first_scheduled([
    %StopTime{departure: {%Schedule{}, %Prediction{time: prediction_time}}} = first,
    %StopTime{departure: {%Schedule{time: schedule_time}, nil}}
    | rest])
  when schedule_time < prediction_time do
    [first | rest]
  end
  defp remove_first_scheduled(stop_times), do: stop_times

  @spec predicted_schedule_pairs(Trip.t, %{Trip.t => {Schedule.t, Schedule.t}}, %{Trip.t => %{String.t => Prediction.t}}, String.t, String.t) :: StopTime.t
  defp predicted_schedule_pairs(trip, schedule_map, prediction_map, origin, dest) do
    departure_prediction = prediction_map[trip][origin]
    arrival_prediction = prediction_map[trip][dest]
    case Map.get(schedule_map, trip) do
      {departure, arrival} -> %StopTime{
                              departure: {departure, departure_prediction},
                              arrival: {arrival, arrival_prediction},
                              trip: trip
                          }
      nil -> %StopTime{
             departure: {nil, departure_prediction},
             arrival: {nil, arrival_prediction},
             trip: trip
         }
    end
  end

  @spec predicted_departures(Trip.t, %{Trip.t => %{String.t => Schedule.t}}, %{Trip.t => %{String.t => Prediction.t}}, String.t) :: StopTime.t
  defp predicted_departures(trip, schedule_map, prediction_map, origin) do
    departure_schedule = schedule_map[trip][origin]
    departure_prediction = prediction_map[trip][origin]
    %StopTime{
      departure: {departure_schedule, departure_prediction},
      arrival: nil,
      trip: trip
    }
  end

  @spec get_trips(%{String.t => {Schedule.t, Schedule.t}}, [Prediction.t]) :: [String.t]
  defp get_trips(schedule_map, predictions) do
    predictions
    |> Enum.map(&(&1.trip))
    |> Enum.concat(Map.keys(schedule_map))
    |> Enum.uniq
  end

  @spec build_schedule_pair_map({Schedule.t, Schedule.t}, %{Trip.t => {Schedule.t, Schedule.t}}) :: %{Trip.t => {Schedule.t, Schedule.t}}
  defp build_schedule_pair_map({departure, arrival}, schedule_pair_map) do
    Map.put(schedule_pair_map, departure.trip, {departure, arrival})
  end

  @spec build_prediction_map(Prediction.t, %{String.t => %{String.t => Prediction.t}}) :: %{String.t => %{String.t => Prediction.t}}
  defp build_prediction_map(prediction, prediction_map) do
    updater = fn(trip_map) -> Map.merge(trip_map, %{prediction.stop_id => prediction}) end
    Map.update(prediction_map, prediction.trip, %{prediction.stop_id => prediction}, updater)
  end

  @spec build_schedule_map(Schedule.t, %{String.t => %{String.t => Schedule.t}}) :: %{String.t => %{String.t => Schedule.t}}
  defp build_schedule_map(schedule, schedule_map) do
    updater = fn(trip_map) -> Map.merge(trip_map, %{schedule.stop.id => schedule}) end
    Map.update(schedule_map, schedule.trip, %{schedule.stop.id => schedule}, updater)
  end

  # The expected result is a tuple: {int, time}.
  # Predictions are of the form {0, time} and schedules are of the form {1, time}
  # This ensures predictions are shown first, and then sorted by ascending time
  # Arrival predictions that have no corresponding departures are shown first.
  @spec prediction_sorter(StopTime.t) :: {integer, DateTime.t}
  defp prediction_sorter(%StopTime{departure: {nil, nil}, arrival: {nil, arrival_prediction}}), do: {0, arrival_prediction.time}
  defp prediction_sorter(%StopTime{departure: {scheduled_departure, nil}, arrival: {departure_prediction, arrival_prediction}})
  when not is_nil(departure_prediction) and not is_nil(arrival_prediction) do
    {0, scheduled_departure.time}
  end
  defp prediction_sorter(%StopTime{departure: {_, departure_prediction}}) when not is_nil(departure_prediction) do
    {1, departure_prediction.time}
  end
  defp prediction_sorter(%StopTime{departure: {departure, nil}}) when not is_nil(departure) do
    {2, departure.time}
  end

  @spec limit_trips([any], boolean) :: [any]
  defp limit_trips(trips, false), do: Enum.take(trips, trips_limit())
  defp limit_trips(trips, true), do: trips

  @spec trips_limit() :: integer
  defp trips_limit(), do: 14
end
