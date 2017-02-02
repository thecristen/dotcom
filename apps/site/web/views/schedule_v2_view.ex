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
  def stop_bubble_location_display(false, _route_type, _terminus), do: ""
  def stop_bubble_location_display(true, route_type, true) do
    svg_icon(%SvgIcon{icon: Routes.Route.type_atom(route_type), class: "icon-small icon-inverse"})
  end
  def stop_bubble_location_display(true, route_type, false) do
    svg_icon(%SvgIcon{icon: Routes.Route.type_atom(route_type), class: "icon-small icon-boring"})
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
end
