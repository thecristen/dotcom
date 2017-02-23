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
  plug Site.ScheduleController.AllStops
  plug SV2C.OriginDestination
  plug SV2C.VehicleLocations
  plug SV2C.Predictions
  plug Site.ScheduleController.Headsigns
  plug SV2C.ExcludedStops
  plug Site.ScheduleController.RouteBreadcrumbs
  plug :tab_assigns

  def show(conn, _) do
    conn
    |> render("show.html")
  end

  defp tab(%Plug.Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, _opts) do
    tab = if conn.params["tab"] == "trip-view", do: "trip-view", else: "timetable"
    conn
    |> assign(:tab, tab)
    |> assign(:schedule_template, "_commuter.html")
  end
  defp tab(conn, _opts) do
    conn
    |> assign(:tab, "trip-view")
    |> assign(:schedule_template, "_default_schedule.html")
  end

  defp assign_trip_schedules(conn) do
    timetable_schedules = timetable_schedules(conn)
    header_schedules = header_schedules(timetable_schedules)
    trip_schedules = Map.new(timetable_schedules, & {{&1.trip.id, &1.stop.id}, &1})

    conn
    |> assign(:timetable_schedules, timetable_schedules)
    |> assign(:header_schedules, header_schedules)
    |> assign(:trip_schedules, trip_schedules)
  end

  defp timetable_schedules(%{assigns: %{date: date, route: route, direction_id: direction_id}}) do
    Schedules.Repo.all(date: date, route: route.id, direction_id: direction_id)
  end

  defp header_schedules(timetable_schedules) do
    timetable_schedules
    |> Schedules.Sort.sort_by_first_times
    |> Enum.map(&List.first/1)
  end

  defmacrop call_plug(conn, module) do
    opts = Macro.expand(module, __ENV__).init([])
    quote do
      unquote(module).call(unquote(conn), unquote(opts))
    end
  end

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
end
