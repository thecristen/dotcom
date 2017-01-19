defmodule Site.ScheduleV2View do
  use Site.Web, :view

  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.Schedule

  @type optional_schedule :: Schedule.t | nil
  @type scheduled_prediction :: {optional_schedule, Prediction.t | nil}

  defdelegate build_calendar(date, holidays, conn), to: Site.ScheduleV2.Calendar

  def update_schedule_url(conn, query) do
    conn
    |> Site.ViewHelpers.update_query(query)
    |> Map.pop("route")
    |> elem(1)
    |> do_update_url(conn)
  end

  defp do_update_url(updated, conn) when updated == %{} do
    conn.request_path
  end
  defp do_update_url(updated, conn) do
    "#{conn.request_path}?#{URI.encode_query(updated)}"
  end

  @doc "Subtract one month from given date"
  @spec decrement_month(Date.t) :: Date.t
  def decrement_month(date), do: shift_month(date, -1)

  @doc "Add one month from given date"
  @spec add_month(Date.t) :: Date.t
  def add_month(date), do: shift_month(date, 1)

  @spec shift_month(Date.t, integer) :: Date.t
  defp shift_month(date, delta) do
    date
    |> Timex.beginning_of_month
    |> Timex.shift(months: delta)
  end

  @doc """
  Class for the previous month link in the date picker. If the given date is during the current month
  or before it is disabled; otherwise it's left as is.
  """
  @spec previous_month_class(Date.t) :: String.t
  def previous_month_class(date) do
    if Util.today.month == date.month or Timex.before?(date, Util.today) do
      " disabled"
    else
      ""
    end
  end

  def reverse_direction_opts(origin, dest, route_id, direction_id) do
    new_origin = dest || origin
    new_dest = dest && origin
    [trip: nil, direction_id: direction_id, route: route_id]
    |> Keyword.merge(
      if Schedules.Repo.stop_exists_on_route?(new_origin, route_id, direction_id) do
        [dest: new_dest, origin: new_origin]
      else
        [dest: nil, origin: nil]
      end
    )
  end

  def stop_info_link(stop) do
    do_stop_info_link(Stops.Repo.get(stop.id))
  end

  defp do_stop_info_link(%{id: id, name: name}) do
    title = "View stop information for #{name}"
    body = ~e(
      <%= svg_icon %SvgIcon{icon: :map} %>
      <span class="sr-or-no-js"> <%= title %>
    )

      link(
           to: stop_path(Site.Endpoint, :show, id),
           class: "station-info-link",
           data: [
             toggle: "tooltip"
           ],
      title: title,
      do: body)
  end

  def pretty_date(date) do
    if date == Util.service_date do
      "Today"
    else
      Timex.format!(date, "{Mshort} {D}")
    end
  end

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
  @spec get_valid_trip({scheduled_prediction, scheduled_prediction}) :: String.t
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

  @doc """
  Turns route into a human-readable string:
    - "Bus Route" <> route.name for bus routes
    - route.name for all other route types
  """
  @spec full_route_name(Route.t) :: String.t
  def full_route_name(%Route{type: 3, name: name}), do: "Bus Route " <> name
  def full_route_name(%Route{name: name}), do: name

  @doc """
  Calculates the difference in minutes between the start and end of the trip.
  """
  @spec scheduled_duration([Schedule.t]) :: String.t
  def scheduled_duration(trip_schedules) do
    do_scheduled_duration List.first(trip_schedules), List.last(trip_schedules)
  end

  @spec do_scheduled_duration(Schedule.t, Schedule.t) :: String.t
  defp do_scheduled_duration(%Schedule{time: origin}, %Schedule{time: destination}) do
    destination
    |> Timex.diff(origin, :minutes)
    |> Integer.to_string
  end
  defp do_scheduled_duration(nil, nil), do: ""
end
