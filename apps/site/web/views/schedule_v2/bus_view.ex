defmodule Site.ScheduleV2.BusView do
  use Site.Web, :view

  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction

  @type schedule_with_predictions :: {Schedule.t, Schedule.t, Prediction.t | nil, Prediction.t | nil}

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

  def display_time(scheduled, nil) do
    content_tag :span do
      Timex.format!(scheduled.time, "{0h12}:{m}{AM}")
    end
  end
  def display_time(_scheduled, prediction) do
    content_tag :span do
      [
        fa("rss"),
        " ",
        Timex.format!(prediction.time, "{0h12}:{m}{AM}")
      ]
    end
  end

  @doc "Group Schedules and Predictions by trip id"
  @spec group_trips([{Schedule.t, Schedule.t}], [Prediction.t], [Prediction.t]) :: [schedule_with_predictions]
  def group_trips(schedules, origin_predictions, destination_predictions) do
    departure_predictions = Enum.map(origin_predictions, &({:departure, &1}))
    arrival_predictions = Enum.map(destination_predictions, &({:arrival, &1}))

    schedules
    |> Enum.concat(departure_predictions)
    |> Enum.concat(arrival_predictions)
    |> Enum.group_by(&get_trip_id/1)
    |> Enum.map(&normalize_group/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(&(Timex.after?(elem(&1, 0).time, Timex.now))) # Don't show anything that has already left
    |> Enum.sort_by(&(elem(&1, 0).time))
  end

  # Provides the trip id for the prediction or schedule
  @spec get_trip_id({:arrival | :departure, Prediction.t} | {Schedule.t, Schedule.t}) :: String.t
  defp get_trip_id({_label, %Prediction{trip: trip}}), do: trip.id
  defp get_trip_id({%Schedule{trip: trip}, _destination}), do: trip.id

  # Formats all groups as {schedule, destination, departure_prediction, arrival_prediction}
  @spec normalize_group({String.t, [{Schedule.t, Schedule.t} | {:arrival | :departure, Prediction.t}]}) :: schedule_with_predictions
  defp normalize_group({_, [{schedule, destination}, {:departure, departure_prediction}, {:arrival, arrival_prediction}]}) do
    {schedule, destination, departure_prediction, arrival_prediction}
  end
  defp normalize_group({_, [{schedule, destination}, {:departure, prediction}]}) do
    {schedule, destination, prediction, nil}
  end
  defp normalize_group({_, [{schedule, destination}, {:arrival, prediction}]}) do
    {schedule, destination, nil, prediction}
  end
  defp normalize_group({_, [{%Schedule{} = schedule, %Schedule{} = destination}]}) do
    {schedule, destination, nil, nil}
  end
  defp normalize_group(_) do # Prediction without available trip
    nil
  end
end
