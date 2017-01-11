defmodule Site.ScheduleV2.BusView do
  use Site.Web, :view

  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction

  @type optional_schedule :: Schedule.t | nil
  @type scheduled_prediction :: {optional_schedule, Prediction.t | nil}

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

  @doc "Group schedules and predictions together according to trip_id and stop_id"
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
    departure_prediction = get_in(prediction_map, [trip_id, origin])
    arrival_prediction = get_in(prediction_map, [trip_id, dest])
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
  defp trip_id_and_schedule_pair({schedule, destination}) do
    {schedule.trip.id, {schedule, destination}}
  end

  @spec build_prediction_map(Prediction.t, %{String.t => %{String.t => Prediction.t}}) :: %{String.t => %{String.t => Prediction.t}}
  defp build_prediction_map(prediction, prediction_map) do
    case Map.has_key?(prediction_map, prediction.trip.id) do
      false -> Map.put(prediction_map, prediction.trip.id, %{prediction.stop_id => prediction})
      true -> put_in(prediction_map, [prediction.trip.id, prediction.stop_id], prediction)
    end
  end

  @spec prediction_sorter({scheduled_prediction, scheduled_prediction}) :: {integer, DateTime.t}
  defp prediction_sorter({{nil, departure}, {nil, _arrival}}) when not is_nil(departure), do: {0, departure.time}
  defp prediction_sorter({{nil, _departure}, {nil, arrival}}), do: {0, arrival.time}
  defp prediction_sorter({{_departure, departure_prediction}, {_, _}}) when not is_nil(departure_prediction), do: {0, departure_prediction.time}
  defp prediction_sorter({{_departure, nil}, {_arrival, arrival_prediction}}) when not is_nil(arrival_prediction), do: {0, arrival_prediction.time}
  defp prediction_sorter({{departure, _}, {_arrival, _}}), do: {1, departure.time}

end
