defmodule Site.ScheduleV2.BusView do
  use Site.Web, :view
  import Site.ScheduleV2.TripInfoView

  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction

  @type optional_schedule :: Schedule.t | nil
  @type scheduled_prediction :: {optional_schedule, Prediction.t | nil}

  @doc """
  Given a list of schedules, returns a display of the route direction. Assumes all
  schedules have the same route and direction.
  """
  @spec display_direction([Schedule.t]) :: iodata
  def display_direction([%Schedule{route: route, trip: %Trip{direction_id: direction_id}}|_]) do
    [direction(direction_id, route), " to"]
  end
  def display_direction([{%Schedule{route: route, trip: %Trip{direction_id: direction_id}}, _} | _]) do
    [direction(direction_id, route), " to"]
  end
  def display_direction([]), do: ""

  @doc """
  Takes a list of predictions and a list of schedules and returns the information necessary to display
  them on the schedule page. For any one trip, we prefer the predicted time, and we always show any predictions
  before schedules.
  """
  @spec merge_predictions_and_schedules([Prediction.t], [Schedule.t]) :: [Prediction.t | Schedule.t]
  def merge_predictions_and_schedules(predictions, schedules) do
    predictions
    |> Enum.concat(schedules)
    |> Enum.uniq_by(&(&1.trip.id))
    |> Enum.sort_by(&(&1.time))
    |> limit_departures
  end

  # Show predictions first, then scheduled departures.
  @spec limit_departures([Prediction.t | Schedule.t]) :: [Prediction.t | Schedule.t]
  defp limit_departures(departures) do
    scheduled_after_predictions = departures
    |> Enum.reverse
    |> Enum.take_while(&(match?(%Schedule{}, &1)))
    |> Enum.reverse

    predictions = departures
    |> Enum.filter(&(match?(%Prediction{}, &1)))

    predictions
    |> Enum.concat(scheduled_after_predictions)
  end

  def schedules_between_stops(schedules, from_id, to_id) do
    schedules
    |> filter_beginning(from_id)
    |> filter_end(to_id)
  end

  defp filter_beginning(schedules, from_id) do
    Enum.drop_while(schedules, &(&1.stop.id !== from_id))
  end

  defp filter_end(schedules, nil) do
    schedules
  end
  defp filter_end(schedules, to_id) do
    schedules
    |> Enum.reverse
    |> Enum.drop_while(&(&1.stop.id !== to_id))
    |> Enum.reverse
  end

  @doc "Display Prediction time with rss icon if available. Otherwise display scheduled time"
  @spec display_scheduled_prediction(scheduled_prediction) :: Phoenix.HTML.Safe.t | String.t
  def display_scheduled_prediction({nil, nil}), do: ""
  def display_scheduled_prediction({scheduled, nil}) do
    content_tag :span do
      format_schedule_time(scheduled.time)
    end
  end
  def display_scheduled_prediction({_scheduled, prediction}) do
    content_tag :span do
      [
        fa("rss"),
        " ",
      format_schedule_time(prediction.time)
      ]
    end
  end

  @doc """
  Groups schedules and predictions together according to trip_id and stop_id.
  The end is results is a list of {scheduled_prediction, scheduled_prediction}.
  Each {scheduled_prediction, scheduled_prediction} tuple belongs to the same trip.
  Each scheduled_prediction is a schedule and prediction that belong to the same stop.
  """
  @spec group_trips([Schedule.t], [Prediction.t], String.t, String.t) :: [{scheduled_prediction, scheduled_prediction}]
  def group_trips(schedules, predictions, origin, dest) do
    schedule_map = Map.new(schedules, &trip_id_and_schedule_pair/1)
    prediction_map = Enum.reduce(predictions, %{}, &build_prediction_map/2)

    schedule_map
    |> get_trip_ids(predictions)
    |> Enum.map(&(predicted_schedule_pairs(&1, schedule_map, prediction_map, origin, dest)))
    |> Enum.sort_by(&prediction_sorter/1)
  end

  @spec predicted_schedule_pairs(String.t, %{String.t => {Schedule.t, Schedule.t}}, %{String.t => %{String.t => Prediction.t}}, String.t, String.t) :: {scheduled_prediction, scheduled_prediction}
  defp predicted_schedule_pairs(trip_id, schedule_map, prediction_map, origin, dest) do
    departure_prediction = prediction_map[trip_id][origin]
    arrival_prediction = prediction_map[trip_id][dest]
    case Map.get(schedule_map, trip_id) do
      {departure, arrival} -> {{departure, departure_prediction}, {arrival, arrival_prediction}}
      nil -> {{nil, departure_prediction}, {nil, arrival_prediction}}
    end
  end

  @spec get_trip_ids(%{String.t => {Schedule.t, Schedule.t}}, [Prediction.t]) :: [String.t]
  defp get_trip_ids(schedule_map, predictions) do
    predictions
    |> Enum.map(&(&1.trip.id))
    |> Enum.concat(Map.keys(schedule_map))
    |> Enum.uniq
  end

  @spec trip_id_and_schedule_pair({Schedule.t, Schedule.t}) :: {String.t, {Schedule.t, Schedule.t}}
  defp trip_id_and_schedule_pair({departure, arrival}) do
    {departure.trip.id, {departure, arrival}}
  end

  @spec build_prediction_map(Prediction.t, %{String.t => %{String.t => Prediction.t}}) :: %{String.t => %{String.t => Prediction.t}}
  defp build_prediction_map(prediction, prediction_map) do
    updater = fn(trip_id_map) -> Map.merge(trip_id_map, %{prediction.stop_id => prediction}) end
    Map.update(prediction_map, prediction.trip.id, %{prediction.stop_id => prediction}, updater)
  end

  # The expected result is a tuple: {int, time}.
  # Predictions are of the form {0, time} and schedules are of the form {1, time}
  # This ensures predictions are shown first, and then sorted by ascending time
  # Arrival predictions that have no corresponding departures are shown first.
  @spec prediction_sorter({scheduled_prediction, scheduled_prediction}) :: {integer, DateTime.t}
  defp prediction_sorter({{nil, nil}, {nil, arrival_prediction}}), do: {0, arrival_prediction.time}
  defp prediction_sorter({{_, departure_prediction}, _}) when not is_nil(departure_prediction) do
    {1, departure_prediction.time}
  end
  defp prediction_sorter({{departure, nil}, _}) when not is_nil(departure) do
    {2, departure.time}
  end

  @doc "Given a scheduled_prediction, returns a valid trip id for the trip_pair"
  @spec get_valid_trip(scheduled_prediction) :: String.t
  def get_valid_trip({{nil, prediction}, _}) when not is_nil(prediction), do: prediction.trip.id
  def get_valid_trip({{nil, nil}, {_, prediction}}), do: prediction.trip.id
  def get_valid_trip({{departure, _}, _}), do: departure.trip.id

  @spec all_trips([any], boolean) :: [any]
  @doc """
  Takes a list of trips, and a boolean. If false, the trip list will be limited to `trips_limit()` trips.
  Otherwise, all trips are returned
  """
  def all_trips(trips, false), do: Enum.take(trips, trips_limit())
  def all_trips(trips, true), do: trips

  @spec trips_limit() :: integer
  defp trips_limit(), do: 14
end
