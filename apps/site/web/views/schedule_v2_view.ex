defmodule Site.ScheduleV2View do
  use Site.Web, :view

  alias Schedules.Schedule

  defdelegate update_schedule_url(conn, opts), to: UrlHelpers, as: :update_url

  def pretty_date(date) do
    if date == Util.service_date do
      "Today"
    else
      Timex.format!(date, "{Mshort} {D}")
    end
  end

  @spec last_departure([{Schedule.t, Schedule.t}] | [Schedule.t]) :: DateTime.t
  def last_departure([{%Schedule{}, %Schedule{}} | _] = schedules) do
    schedule = schedules
    |> List.last
    |> elem(0)

    schedule.time
  end
  def last_departure(schedules) do
    List.last(schedules).time
  end

  @doc """
  Given a list of schedules, returns a display of the route direction. Assumes all
  schedules have the same route and direction.
  """
  @spec display_direction(StopTimeList.t) :: iodata
  def display_direction(%StopTimeList{times: times}) do
    do_display_direction(times)
  end

  @spec do_display_direction([StopTimeList.StopTime.t]) :: iodata
  defp do_display_direction([%StopTimeList.StopTime{departure: %PredictedSchedule{schedule: nil}} | rest]) do
    do_display_direction(rest)
  end
  defp do_display_direction([%StopTimeList.StopTime{departure: %PredictedSchedule{schedule: scheduled}} | _]) do
    [direction(scheduled.trip.direction_id, scheduled.route), " to"]
  end
  defp do_display_direction([]), do: ""

  @doc "Display Prediction time with rss icon if available. Otherwise display scheduled time"
  @spec display_scheduled_prediction(PredictedSchedule.t) :: Phoenix.HTML.Safe.t | String.t
  def display_scheduled_prediction(%PredictedSchedule{schedule: nil, prediction: nil}), do: ""
  def display_scheduled_prediction(%PredictedSchedule{schedule: scheduled, prediction: nil}) do
    content_tag :span do
      format_schedule_time(scheduled.time)
    end
  end
  def display_scheduled_prediction(%PredictedSchedule{prediction: prediction}) do
    content_tag :span do
      [
        fa("rss"),
        " ",
        format_schedule_time(prediction.time)
      ]
    end
  end

  @doc """
  Given a Vehicle and a route, returns an icon for the route. Given nil, returns nothing. Adds a
  class to indicate that the vehicle is at a trip endpoint if the third parameter is true.
  """
  @spec stop_bubble_location_display(boolean, integer, boolean) :: Phoenix.HTML.Safe.t
  def stop_bubble_location_display(vehicle?, route_type, terminus?)
  def stop_bubble_location_display(true, route_type, true) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Routes.Route.type_atom(route_type), class: "icon-inverse"})
  end
  def stop_bubble_location_display(true, route_type, false) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Routes.Route.type_atom(route_type), class: "icon-boring"})
  end
  def stop_bubble_location_display(false, _route_type, true) do
    stop_bubble_icon(:filled)
  end
  def stop_bubble_location_display(false, _, false) do
    stop_bubble_icon(:open)
  end

  defp stop_bubble_icon(class) do
    content_tag :svg, viewBox: "0 0 42 42", class: "icon trip-bubble-#{class}" do
      tag :circle, r: 20, cx: 20, cy: 20, transform: "translate(2,2)"
    end
  end

  @doc """
  Takes a list of schedules and a conn with `offset` assigned, and selects the range of schedules to be displayed.
  """
  @spec offset_schedules([Schedule.t], Plug.Conn.t) :: [Schedule.t]
  def offset_schedules(schedules, %Plug.Conn{assigns: %{offset: offset}}) do
    schedules
    |> Enum.drop(offset)
    |> Enum.take(num_schedules())
  end

  @doc "The number of trip schedules to show at a time."
  @spec num_schedules :: non_neg_integer
  def num_schedules(), do: 6

  @doc "The link to see earlier schedules."
  @spec earlier_link(Plug.Conn.t) :: Phoenix.HTML.Safe.t
  def earlier_link(%Plug.Conn{assigns: %{offset: offset}} = conn) do
    schedule_time_link(
      update_url(conn, offset: offset - 1),
      "earlier",
      "angle-left",
      offset == 0
    )
  end

  @doc "The link to see later schedules."
  @spec later_link(Plug.Conn.t) :: Phoenix.HTML.Safe.t
  def later_link(%Plug.Conn{assigns: %{offset: offset, header_schedules: header_schedules}} = conn) do
    schedule_time_link(
      update_url(conn, offset: offset + 1),
      "later",
      "angle-right",
      offset >= length(header_schedules) - num_schedules()
    )
  end

  @spec schedule_time_link(String.t, String.t, String.t, boolean) :: Phoenix.HTML.Safe.t
  defp schedule_time_link(url, time_text, icon, disabled?) do
    text = if disabled? do
      ["There are no ", time_text, " trips"]
    else
      ["Show ", time_text, " times"]
    end
    link to: url, class: "#{if disabled?, do: "disabled ", else: ""}btn btn-link" do
      [
        fa(icon),
        content_tag(:span, text, class: "sr-only")
      ]
    end
  end

  @doc """
  Displays the CR icon if given a non-nil vehicle location. Otherwise, displays nothing.
  """
  @spec timetable_location_display(Vehicles.Vehicle.t | nil) :: Phoenix.HTML.Safe.t
  def timetable_location_display(%Vehicles.Vehicle{}) do
    svg_icon %SvgIcon{icon: :commuter_rail, class: "icon-small"}
  end
  def timetable_location_display(_location), do: ""

  @spec tab_selected?(tab :: String.t, current_tab :: String.t | nil) :: boolean()
  @doc """
  Given a schedule tab, and the selected tab, returns whether or not the schedule tab should be rendered as selected.
  """
  def tab_selected?(tab, tab), do: true
  def tab_selected?(_, _), do: false

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template for the selected tab."
  def template_for_tab("trip-view"), do: "_trip_view.html"
  def template_for_tab("timetable"), do: "_timetable.html"

  @spec reverse_direction_opts(Stops.Stop.t | nil, Stops.Stop.t | nil, 0..1) :: Keyword.t
  def reverse_direction_opts(origin, destination, direction_id) do
    origin_id = if origin, do: origin.id, else: nil
    destination_id = if destination, do: destination.id, else: nil

    new_origin_id = destination_id || origin_id
    new_dest_id = destination_id && origin_id

    [trip: nil, direction_id: direction_id, destination: new_dest_id, origin: new_origin_id]
  end

  @doc """
  If scheduled and predicted times differ, displays the scheduled time crossed out, with the predicted
  time below it. Otherwise just displays the time as display_scheduled_prediction/1 does.
  """
  @spec display_commuter_scheduled_prediction(PredictedSchedule.t) :: Phoenix.HTML.Safe.t | String.t
  def display_commuter_scheduled_prediction(%PredictedSchedule{schedule: schedule, prediction: prediction} = stop_time) do
    case StopTimeList.StopTime.delay(stop_time) do
      # if we're going to show both, make sure they are different times
      delay when delay > 0 -> content_tag :span, do: [
        content_tag(:del, format_schedule_time(schedule.time)),
        tag(:br),
        fa("rss"),
        " ",
        format_schedule_time(prediction.time)
      ]
        # otherwise just show the scheduled or predicted time as appropriate
      _ -> display_scheduled_prediction(stop_time)
    end
  end

  @doc """
  Returns Trip Alerts by the trip id and time from the given predicted_schedule, route and direction_id
  If no schedule is available, the prediction is used to match against alerts
  """
  @spec trip_alerts(PredictedSchedule.t | nil, [Alerts.Alert.t],  String.t, String.t) :: [Alerts.Alert.t]
  def trip_alerts(nil, _alerts, _route_id, _direction_id), do: []
  def trip_alerts(%PredictedSchedule{schedule: nil, prediction: nil}, _alerts, _route_id, _direction_id), do: []
  def trip_alerts(%PredictedSchedule{schedule: nil, prediction: prediction}, alerts, route_id, direction_id) do
    Alerts.Trip.match(alerts, prediction.trip.id, time: prediction.time, route: route_id, direction_id: direction_id)
  end
  def trip_alerts(%PredictedSchedule{schedule: schedule}, alerts, route_id, direction_id) do
    Alerts.Trip.match(alerts, schedule.trip.id, time: schedule.time, route: route_id, direction_id: direction_id)
  end

  @doc """
  Matches the given alerts with the stop id and time from the given predicted_schedule, route and direction_id
  If no schedule is available, the prediction is used to match against alerts
  """
  @spec stop_alerts(PredictedSchedule.t | nil, [Alerts.Alert.t],  String.t, String.t) :: [Alerts.Alert.t]
  def stop_alerts(nil, _alerts, _route_id, _direction_id), do: []
  def stop_alerts(%PredictedSchedule{schedule: nil, prediction: prediction}, alerts, route_id, direction_id) do
    Alerts.Stop.match(alerts, prediction.stop_id, time: prediction.time, route: route_id, direction_id: direction_id)
  end
  def stop_alerts(%PredictedSchedule{schedule: schedule}, alerts, route_id, direction_id) do
    Alerts.Stop.match(alerts, schedule.stop.id, time: schedule.time, route: route_id, direction_id: direction_id)
  end

  @doc "If alerts are given, display alert icon"
  @spec display_alerts([Alerts.Alert.t]) :: Phoenix.HTML.Safe.t
  def display_alerts([]), do: raw ""
  def display_alerts(_alerts), do: svg_icon(%SvgIcon{icon: :alert, class: "icon-small"})

  @spec prediction_status_text(Predictions.Prediction.t | nil) :: String.t
  def prediction_status_text(%Predictions.Prediction{status: status, track: track}) when not is_nil(track) do
    "#{status} on Track #{track}"
  end
  def prediction_status_text(_) do
    ""
  end

  @spec prediction_time_text(Predictions.Prediction.t | nil) :: String.t
  def prediction_time_text(nil) do
    ""
  end
  def prediction_time_text(%Predictions.Prediction{time: nil}) do
    ""
  end
  def prediction_time_text(%Predictions.Prediction{time: time}) do
    "Arrival: #{Timex.format!(time, "{h12}:{m} {AM}")}"
  end

  @spec build_prediction_tooltip(String.t, String.t) :: Phoenix.HTML.Safe.t
  def build_prediction_tooltip("", "") do
    nil
  end
  def build_prediction_tooltip(time_text, "") do
    content_tag :span do
      time_text
    end
  end
  def build_prediction_tooltip("", status_text) do
    content_tag :span do
      status_text
    end
  end
  def build_prediction_tooltip(time_text, status_text) do
    time_tag = content_tag(:p, time_text, class: 'prediction-tooltip')
    status_tag = content_tag(:p, status_text, class: 'prediction-tooltip')

    :span
    |> content_tag([time_tag, status_tag])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end

  @spec prediction_tooltip(Predictions.Prediction.t) :: Phoenix.HTML.Safe.t
  def prediction_tooltip(prediction) do
    time_text = prediction_time_text(prediction)
    status_text = prediction_status_text(prediction)

    build_prediction_tooltip(time_text, status_text)
  end

  @spec prediction_for_vehicle_location(Plug.Conn.t, String.t, String.t) :: Predictions.Prediction.t
  def prediction_for_vehicle_location(%{assigns: %{vehicle_predictions: vehicle_predictions}}, stop_id, trip_id) do
    vehicle_predictions
    |> Enum.find(fn prediction -> prediction.stop_id == stop_id && prediction.trip.id == trip_id end)
  end
  def prediction_for_vehicle_location(conn, _stop_id, _trip_id) do
    conn
  end

  @doc """
  Returns vehicle frequency for the frequency table, either "Every X minutes" or "No service between these hours".
  """
  @spec frequency_times(boolean, Schedules.Frequency.t) :: Phoenix.HTML.Safe.t
  def frequency_times(false, _), do: content_tag :span, "No service between these hours"
  def frequency_times(true, frequency) do
    content_tag :span do
      [
        "Every ",
        TimeGroup.display_frequency_range(frequency),
        content_tag(:span, " minutes", class: "sr-only"),
        content_tag(:span, " mins", aria_hidden: true)
      ]
    end
  end

  @spec frequency_block_name(Schedules.Frequency.t) :: String.t
  defp frequency_block_name(%Schedules.Frequency{time_block: :am_rush}), do: "OPEN - 9:00AM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :midday}), do: "9:00AM - 3:30PM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :pm_rush}), do: "3:30PM - 6:30PM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :evening}), do: "6:30PM - 8:00PM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :late_night}), do: "8:00PM - CLOSE"
end
