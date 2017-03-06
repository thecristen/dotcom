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

  def show(conn, _) do
    conn
    |> render("show.html")
  end

  defp tab(%Plug.Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, _opts) do
    tab = conn.params["tab"] || "timetable"
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
    |> assign(:trip_messages, trip_messages(conn.assigns.route, conn.assigns.direction_id))
  end

  defp timetable_schedules(%{assigns: %{date: date, route: route, direction_id: direction_id}}) do
    Schedules.Repo.all(date: date, route: route.id, direction_id: direction_id)
  end

  defp header_schedules(timetable_schedules) do
    timetable_schedules
    |> Schedules.Sort.sort_by_first_times
    |> Enum.map(&List.first/1)
  end

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
    conn = conn
    |> call_plug(SV2C.LineHoursOfOperation)
    |> call_plug(SV2C.LineNextThreeHolidays)
    |> call_plug(SV2C.Line)
  end
end
