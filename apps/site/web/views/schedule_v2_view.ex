defmodule Site.ScheduleV2View do
  use Site.Web, :view

  alias Schedules.{Schedule, Trip}
  alias Routes.Route
  alias Schedules.Schedule

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
    body = ~e(<%= svg_icon %SvgIcon{icon: :map} %><span class="sr-or-no-js"><%= title %></span>)

    link body,
      to: stop_path(Site.Endpoint, :show, id),
      class: "station-info-link",
      data: [toggle: "tooltip"],
      title: title
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
  @spec display_direction(StopTimeList.t) :: iodata
  def display_direction(%StopTimeList{times: times}) do
    do_display_direction(times)
  end

  @spec do_display_direction([StopTimeList.StopTime.t]) :: iodata
  defp do_display_direction([%StopTimeList.StopTime{departure: {nil, _}} | rest]) do
    do_display_direction(rest)
  end
  defp do_display_direction([%StopTimeList.StopTime{departure: {scheduled, _}} | _]) do
    [direction(scheduled.trip.direction_id, scheduled.route), " to"]
  end
  defp do_display_direction([]), do: ""

  @doc "Display Prediction time with rss icon if available. Otherwise display scheduled time"
  @spec display_scheduled_prediction(StopTimeList.StopTime.predicted_schedule) :: Phoenix.HTML.Safe.t | String.t
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
  Given a Vehicle and a route, returns an icon for the route. Given nil, returns nothing. Adds a
  class to indicate that the vehicle is at a trip endpoint if the third parameter is true.
  """
  @spec stop_bubble_location_display(boolean, Routes.Route.t, boolean) :: Phoenix.HTML.Safe.t
  def stop_bubble_location_display(vehicle?, route, terminus?)
  def stop_bubble_location_display(false, _route, _terminus), do: ""
  def stop_bubble_location_display(true, route, true) do
    svg_icon(%SvgIcon{icon: route, class: "icon-small icon-inverse"})
  end
  def stop_bubble_location_display(true, route, false) do
    svg_icon(%SvgIcon{icon: route, class: "icon-small icon-boring"})
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
      Site.ScheduleV2View.update_schedule_url(conn, offset: offset - 1),
      "earlier",
      "angle-left",
      offset == 0
    )
  end

  @doc "The link to see later schedules."
  @spec later_link(Plug.Conn.t) :: Phoenix.HTML.Safe.t
  def later_link(%Plug.Conn{assigns: %{offset: offset, all_schedules: all_schedules}} = conn) do
    schedule_time_link(
      Site.ScheduleV2View.update_schedule_url(conn, offset: offset + 1),
      "later",
      "angle-right",
      offset >= length(all_schedules) - num_schedules()
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

  @spec display_train_number(StopTimeList.StopTime.predicted_schedule) :: String.t
  def display_train_number({%Schedule{trip: %Trip{name: name}}, _predicted}) do
    name
  end
end
