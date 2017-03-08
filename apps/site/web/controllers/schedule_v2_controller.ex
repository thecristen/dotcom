defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller

  alias Site.ScheduleV2Controller, as: SV2C

  plug Site.Plugs.Route, required: true
  plug :tab
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.ScheduleController.DatePicker
  plug SV2C.Defaults
  plug Site.Plugs.Alerts
  plug SV2C.AllStops
  plug SV2C.OriginDestination
  plug SV2C.ExcludedStops
  plug SV2C.PreSelect
  plug SV2C.VehicleLocations
  plug SV2C.Predictions
  plug Site.ScheduleController.Headsigns
  plug Site.ScheduleController.RouteBreadcrumbs
  plug :tab_assigns

  @spec show(Plug.Conn.t, map) :: Phoenix::HTML.Safe.t
  def show(conn, _) do
    conn
    |> render("show.html")
  end

  # Plug that assigns the tab based on a URL parameter or a default value to the connection
  @spec tab(Plug.Conn.t, map) :: Plug.Conn.t
  defp tab(%Plug.Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, _opts) do
    tab = case conn.params["tab"] do
      "trip-view" ->
        "trip-view"
      "line" ->
        "line"
      _ ->
        "timetable"
    end
    conn
    |> assign(:tab, tab)
    |> assign(:schedule_template, "_commuter.html")
  end
  defp tab(conn, _opts) do
    tab = case conn.params["tab"] do
      "line" ->
        "line"
      _ ->
        "trip-view"
    end
    conn
    |> assign(:tab, tab)
    |> assign(:schedule_template, "_default_schedule.html")
  end

  # Plug that assigns trip schedule to the connection
  @spec assign_trip_schedules(Plug.Conn.t) :: Plug.Conn.t
  defp assign_trip_schedules(conn) do
    timetable_schedules = timetable_schedules(conn)
    header_schedules = header_schedules(timetable_schedules)
    trip_schedules = Map.new(timetable_schedules, & {{&1.trip.id, &1.stop.id}, &1})

    conn
    |> assign(:timetable_schedules, timetable_schedules)
    |> assign(:header_schedules, header_schedules)
    |> assign(:trip_schedules, trip_schedules)
    |> assign(:trip_messages, trip_messages(conn.assigns.route, conn.assigns.direction_id))
  end

  # Helper function for obtaining schedule data
  @spec timetable_schedules(Plug.Conn.t) :: [Schedules.Schedule.t]
  defp timetable_schedules(%{assigns: %{date: date, route: route, direction_id: direction_id}}) do
    Schedules.Repo.all(date: date, route: route.id, direction_id: direction_id)
  end

  @spec header_schedules(list) :: list
  defp header_schedules(timetable_schedules) do
    timetable_schedules
    |> Schedules.Sort.sort_by_first_times
    |> Enum.map(&List.first/1)
  end

  @spec trip_messages(Routes.Route.t, 0 | 1) :: %{{String.t, String.t} => String.t}
  defp trip_messages(%Routes.Route{id: "CR-Lowell"}, 0) do
    %{
      {"221", "North Billerica"} => "Via",
      {"221", "Lowell"} => "Haverhill"
    }
  end
  defp trip_messages(%Routes.Route{id: "CR-Haverhill"}, 0) do
    %{
      {"221", "Melrose Highlands"} => "Via",
      {"221", "Greenwood"} => "Lowell"
    }
  end
  defp trip_messages(%Routes.Route{id: "CR-Franklin"}, 1) do
    %{
      {"790", "place-rugg"} => "Via",
      {"790", "place-bbsta"} => "Fairmount",
      {"746", "place-rugg"} => "Via",
      {"746", "place-bbsta"} => "Fairmount"
    }
  end
  defp trip_messages(_, _) do
    %{}
  end

  defmacrop call_plug(conn, module) do
    opts = Macro.expand(module, __ENV__).init([])
    quote do
      unquote(module).call(unquote(conn), unquote(opts))
    end
  end

  # Plug that calls other plugs depending on which tab is currently set
  @spec tab_assigns(Plug.Conn.t, map) :: Plug.Conn.t
  defp tab_assigns(%Plug.Conn{assigns: %{tab: "timetable"}} = conn, _opts) do
    conn
    |> assign_trip_schedules
    |> call_plug(SV2C.Offset)
  end
  defp tab_assigns(%Plug.Conn{assigns: %{tab: "trip-view"}} = conn, _opts) do
    conn = conn
    |> call_plug(SV2C.Schedules)
    |> call_plug(SV2C.StopTimes)
    |> call_plug(SV2C.TripInfo)

    if conn.assigns.route.type == 2 do
      assign(conn, :zone_map, Map.new(conn.assigns.all_stops, &{&1.id, Zones.Repo.get(&1.id)}))
    else
      conn
    end
  end
  defp tab_assigns(%Plug.Conn{assigns: %{tab: "line"}} = conn, _opts) do
    conn
    |> call_plug(SV2C.HoursOfOperation)
    |> call_plug(SV2C.NextThreeHolidays)
    |> call_plug(SV2C.Line)
  end

  @spec hours_of_operation(Plug.Conn.t, map) :: Plug.Conn.t
  def hours_of_operation(%Plug.Conn{assigns: %{route: route}, params: %{"route" => route_id}} = conn, opts)
  when (not is_nil(route)) or (route_id == "Green") do
    dates = get_dates(conn.assigns.date)
    schedules_fn = schedules_fn(opts)
    assign(conn, :hours_of_operation, %{
          :week => get_hours(conn, dates[:week], schedules_fn),
          :saturday => get_hours(conn, dates[:saturday], schedules_fn),
          :sunday => get_hours(conn, dates[:sunday], schedules_fn)}
    )
  end
  def hours_of_operation(conn, _opts) do
    conn
  end

  defp get_hours(%Plug.Conn{params: %{"route" => "Green"}}, date, schedules_fn) do
    do_get_hours(Enum.join(GreenLine.branch_ids(), ","), date, schedules_fn)
  end
  defp get_hours(%Plug.Conn{assigns: %{route: route}}, date, schedules_fn) do
    do_get_hours(route.id, date, schedules_fn)
  end

  defp do_get_hours(route_id, date, schedules_fn) do
    {inbound, outbound} = [date: date, stop_sequence: "first,last"]
    |> Keyword.merge(route: route_id)
    |> schedules_fn.()
    |> Enum.split_with(& &1.trip.direction_id == 1)

    %{
      1 => Schedules.Departures.first_and_last_departures(inbound),
      0 => Schedules.Departures.first_and_last_departures(outbound)
    }
  end

  defp get_dates(date) do
    %{
      :week => Timex.end_of_week(date, 2),
      :saturday => Timex.end_of_week(date, 7),
      :sunday => Timex.end_of_week(date, 1)
    }
  end

  defp schedules_fn(opts) do
    Keyword.get(opts, :schedules_fn, &Schedules.Repo.all/1)
  end

  @spec next_3_holidays(Plug.Conn.t, map) :: Plug.Conn.t
  def next_3_holidays(%Plug.Conn{assigns: %{date: date}} = conn, _opts) do
    holidays = date
    |> Holiday.Repo.following
    |> Enum.take(3)

    conn
    |> assign(:holidays, holidays)
  end
  def next_3_holidays(conn, _opts) do
    conn
  end
end
