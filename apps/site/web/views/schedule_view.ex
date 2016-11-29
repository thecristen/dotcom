defmodule Site.ScheduleView do
  use Site.Web, :view
  alias Routes.Route
  alias Schedules.Schedule

  @schedule_display_initial 12
  @schedule_display_buffer 6

  def stop_alerts_for(alerts, stop_ids, opts) do
    stop_ids
    |> Enum.flat_map(fn id -> Alerts.Stop.match(alerts, id, opts) end)
    |> Enum.uniq
  end

  def trip_alerts_for(_, []), do: []
  def trip_alerts_for(alerts, [schedule|_] = schedules) do
    trip_ids = schedules
    |> Enum.map(fn schedule -> schedule.trip.id end)

    Alerts.Trip.match(
      alerts,
      trip_ids,
      time: schedule.time,
      route: schedule.route.id,
      route_type: schedule.route.type,
      direction_id: schedule.trip.direction_id,
      stop: schedule.stop.id
    )
  end
  def trip_alerts_for(alerts, schedule) do
    trip_alerts_for(alerts, [schedule])
  end

  def update_schedule_url(conn, query) do
    new_query = Site.ViewHelpers.update_query(conn, query)

    {route, new_query} = Map.pop(new_query, "route")

    schedule_path(conn, :show, route, new_query |> Enum.into([]))
  end

  def stop_info_link(stop) do
    do_stop_info_link(Stops.Repo.get(stop.id))
  end

  defp do_stop_info_link(%{id: id, name: name}) do
    title = "View stop information for #{name}"
    body = ~e(
      <%= svg_icon %{icon: :map} %>
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

  def most_frequent_headsign(schedules) do
    schedules
    |> Enum.map(&(&1.trip.headsign))
    |> Util.most_frequent_value
  end

  def trip(schedules, from_id, to_id) do
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

  @doc "Return the icon for the schedule row depending on whether it's selected"
  def selected_caret(true) do
    fa "caret-up pull-right"
  end
  def selected_caret(false) do
    fa "caret-down pull-right"
  end

  def schedule_list(schedules, true) do
    schedules
  end
  def schedule_list(schedules, false) do
    if Enum.count(schedules) >= schedule_display_limit do
      Enum.take(schedules, @schedule_display_initial)
    else
      schedules
    end
  end

  def get_hour(%{params: %{"hour" => hour}}), do: hour
  def get_hour(_), do: Util.now.hour |> to_string

  def get_schedule_name(%{params: %{"name" => name}}), do: name
  def get_schedule_name(_) do
    Util.now
    |> TimeGroup.subway_period
    |> to_string
  end

  def prediction_for_schedule(predictions, %Schedule{trip: %{id: trip_id}, stop: %{id: stop_id}}) do
    predictions
    |> Enum.find(fn
      %{trip_id: ^trip_id, stop_id: ^stop_id} -> true
      _ -> false
    end)
  end

  def schedule_display_initial do
    @schedule_display_initial
  end

  def schedule_display_limit do
    @schedule_display_initial + @schedule_display_buffer
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

  @doc "Builds the links that will be displayed on the calendar"
  @spec build_calendar(Date.t, Plug.Conn.t) :: [Phoenix.HTML.Safe.t]
  def build_calendar(date, conn) do
    first_day = date |> Timex.beginning_of_month |> Timex.weekday
    last_day = Timex.end_of_month(date).day
    do_build_calendar(rem(first_day, 7), last_day, 1, [])
    |> Enum.reverse
    |> build_date_links(conn, date)
    |> additional_dates(conn, date)
  end

  @spec do_build_calendar(integer, integer, integer, [integer]) :: [integer]
  defp do_build_calendar(first_day, last_day, current_day, days) do
    cond do
      Enum.count(days) < first_day -> do_build_calendar(first_day, last_day, 1, [0 | days])
      current_day <= last_day -> do_build_calendar(first_day, last_day, current_day + 1, [current_day | days])
      true -> days
    end
  end

  # Fill up the remaining week and add 1 additional week
  @spec additional_dates([integer], Plug.Conn.t, Date.t) :: [Phoenix.HTML.Safe.t]
  defp additional_dates(days, conn, date) do
    links_needed = min((7 - rem(Enum.count(days), 7)) + 7, 13)
    additional = 1..links_needed |> build_date_links(conn, add_month(date))
    Enum.concat(days, additional)
  end

  @spec build_date_links(Enum.t, Plug.Conn.t, Date.t) :: [Phoenix.HTML.Safe.t]
  defp build_date_links(days, conn, date) do
    format_day = fn d -> Timex.format!({date.year,date.month, d}, "%Y-%m-%d", :strftime) end
    date_link = fn 0 -> link("", to: "/")
                   d -> link(d, to: schedule_path(conn, :show, conn.params["route"], date: format_day.(d))) end
    Enum.map(days, date_link)
  end
end
