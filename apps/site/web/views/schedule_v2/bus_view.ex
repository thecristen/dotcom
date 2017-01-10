defmodule Site.ScheduleV2.BusView do
  use Site.Web, :view

  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction

  @type scheduled_prediction :: {Schedule.t, Prediction.t | nil}

  @doc """
  Given a list of schedules, returns a display of the route direction. Assumes all
  schedules have the same route and direction.
  """
  @spec display_direction([Schedule.t]) :: iodata
  def display_direction([
    %Schedule{
      route: route,
      trip: %Trip{direction_id: direction_id}}
    | _]) do
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


  @doc "Display Prediction time with rss icon if available. Otherwise display scheduled time"
  @spec display_scheduled_prediction(scheduled_prediction) :: Phoenix.HTML.Safe.t
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

  @doc "Group schedules and predictions together according to trip_id and stop_id"
  @spec group_trips([Schedule.t], [Prediction.t]) :: [{scheduled_prediction, scheduled_prediction}]
  def group_trips(schedules, predictions) do
    schedule_map = Map.new(schedules, &trip_id_and_schedule_pair/1)
    prediction_map = Map.new(predictions, &trip_stop_and_prediction/1)

    schedule_map
    |> get_trip_ids(predictions)
    |> Enum.map(&(predicted_schedule_pairs(&1, schedule_map, prediction_map)))
    |> Enum.sort_by(&prediction_sorter/1)
  end

  @spec predicted_schedule_pairs(String.t, %{String.t => {Schedule.t, Schedule.t}}, %{{String.t, String.t} => Prediction.t}) :: {scheduled_prediction, scheduled_prediction}
  defp predicted_schedule_pairs(trip_id, schedule_map, prediction_map) do
    {departure, arrival} = Map.get(schedule_map, trip_id)
    departure_prediction = {departure, Map.get(prediction_map, {trip_id, departure.stop.id})}
    arrival_prediction = {arrival, Map.get(prediction_map, {trip_id, arrival.stop.id})}
    {departure_prediction, arrival_prediction}
  end

  @spec get_trip_ids(%{String.t => {Schedule.t, Schedule.t}}, [Prediction.t]) :: [String.t]
  defp get_trip_ids(schedule_map, predictions) do
    predictions
    |> Enum.map(&(&1.trip.id))
    |> Enum.concat(Map.keys(schedule_map))
    |> Enum.uniq
  end

  @spec trip_id_and_schedule_pair({Schedule.t, Schedule.t}) :: {String.t, {Schedule.t, Schedule.t}}
  defp trip_id_and_schedule_pair({schedule, destination}) do
    {schedule.trip.id, {schedule, destination}}
  end

  @spec trip_stop_and_prediction(Prediction.t) :: {{String.t, String.t}, Prediction.t}
  defp trip_stop_and_prediction(prediction) do
    {{prediction.trip.id, prediction.stop_id}, prediction}
  end

  @spec prediction_sorter({scheduled_prediction, scheduled_prediction}) :: {integer, DateTime.t}
  defp prediction_sorter({{departure, nil}, {_arrival, nil}}), do: {1, departure.time}
  defp prediction_sorter({{departure, _departure_prediction}, {_arrival, _arrival_prediction}}), do: {0, departure.time}
end
