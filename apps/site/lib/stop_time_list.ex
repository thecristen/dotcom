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
  @type stop_id :: String.t
  @type schedule_pair :: {Schedule.t, Schedule.t}
  @type schedule_map :: %{Trip.t => %{stop_id => Schedule.t}}
  @type schedule_pair_map :: %{Trip.t => schedule_pair}
  @type prediction_map :: %{Trip.t => %{stop_id => Prediction.t}}

  defmodule StopTime do
    defstruct [:departure, :arrival, :trip]
    @type t :: %__MODULE__{
      departure: predicted_schedule,
      arrival: predicted_schedule | nil,
      trip: Trip.t | nil
    }
    @type predicted_schedule :: {Schedule.t | nil, Prediction.t | nil}

    @spec time(t) :: DateTime.t
    def time(%StopTime{departure: {schedule, nil}}) when not is_nil(schedule) do
      schedule.time
    end
    def time(%StopTime{departure: {_, prediction}}) when not is_nil(prediction) do
      prediction.time
    end

    @doc """
    Returns a message containing the maximum delay between scheduled and predicted times for an arrival
    and departure, or the empty string if there's no delay.
    """
    @spec display_status(__MODULE__.predicted_schedule | nil, __MODULE__.predicted_schedule | nil) :: iodata
    def display_status(departure, arrival \\ nil)
    def display_status({_, %Prediction{status: status, track: track}}, _) when not is_nil(status) do
      case track do
        nil -> status
        track -> [status, " on track ", track]
      end
    end
    def display_status(departure, arrival) do
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

    @doc """
    Returns the time difference between a schedule and prediction. If either is nil, returns 0.
    """
    @spec delay(__MODULE__.predicted_schedule | nil) :: integer
    def delay(nil), do: 0
    def delay({schedule, prediction}) when is_nil(schedule) or is_nil(prediction), do: 0
    def delay({schedule, prediction}) do
      Timex.diff(prediction.time, schedule.time, :minutes)
    end
  end

  @spec build([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil, boolean) :: __MODULE__.t
  def build(schedules, predictions, origin, destination, showing_all?) do
    times = build_times(schedules, predictions, origin, destination)
    from_times(times, showing_all?)
  end

  @doc """
  Build a StopTimeList using only predictions. This will also filter out predictions that are
  missing departure_predictions. Limits to 5 predictions at most.
  """
  @spec build_predictions_only([Prediction.t], String.t | nil, String.t | nil) :: __MODULE__.t
  def build_predictions_only(predictions, origin, destination) do
    []
    |> build_times(predictions, origin, destination)
    |> Enum.filter(&has_departure_prediction?/1)
    |> Enum.take(5)
    |> from_times(true)
  end

  @spec build_times([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil) :: [StopTime.t]
  defp build_times(schedules, predictions, origin, destination) when is_binary(origin) and is_binary(destination) do
    group_trips(
      schedules,
      predictions,
      &build_schedule_pair_map/2,
      &predicted_schedule_pairs(&1, &2, &3, origin, destination)
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
  @spec from_times([StopTime.t], boolean) :: __MODULE__.t
  defp from_times(stop_times, showing_all?) do
    %__MODULE__{
      times: limit_trips(stop_times, showing_all?),
      showing_all?: showing_all?
    }
  end

  defp group_trips(schedules, predictions, build_schedule_map_fn, trip_mapper_fn) do
    prediction_map = Enum.reduce(predictions, %{}, &build_prediction_map/2)
    schedule_map = Enum.reduce(schedules, %{}, build_schedule_map_fn)

    schedule_map
    |> get_trips(predictions)
    |> Enum.map(&(trip_mapper_fn.(&1, schedule_map, prediction_map)))
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

  @spec predicted_schedule_pairs(Trip.t | nil, schedule_pair_map, prediction_map, stop_id, stop_id) :: StopTime.t
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

  @spec predicted_departures(Trip.t | nil, schedule_map, prediction_map, stop_id) :: StopTime.t
  defp predicted_departures(trip, schedule_map, prediction_map, origin) do
    departure_schedule = schedule_map[trip][origin]
    departure_prediction = prediction_map[trip][origin]
    %StopTime{
      departure: {departure_schedule, departure_prediction},
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
  defp limit_trips(trips, false) do
    trips
    |> Enum.sort_by(&prediction_sorter/1)
    |> remove_first_scheduled
    |> Enum.take(trips_limit())
  end
  defp limit_trips(trips, true) do
    trips
    |> Enum.sort_by(&StopTime.time/1)
  end

  @spec trips_limit() :: integer
  defp trips_limit(), do: 14

  @spec has_departure_prediction?(StopTime.t) :: boolean
  defp has_departure_prediction?(%StopTime{departure: {_, nil}}), do: false
  defp has_departure_prediction?(_stop_time), do: true
end
