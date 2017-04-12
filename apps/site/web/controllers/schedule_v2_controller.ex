defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller
  import Site.ControllerHelpers, only: [call_plug: 2]

  alias Site.ScheduleV2Controller, as: SV2C

  plug Site.Plugs.Route
  plug :tab
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug SV2C.DatePicker
  plug SV2C.Defaults
  plug Site.Plugs.Alerts
  plug SV2C.AllStops
  plug SV2C.OriginDestination
  plug SV2C.ExcludedStops
  plug SV2C.PreSelect
  plug SV2C.VehicleLocations
  plug SV2C.Predictions
  plug SV2C.RouteBreadcrumbs
  plug :tab_assigns

  @spec show(Plug.Conn.t, map) :: Phoenix.HTML.Safe.t
  def show(conn, _) do
    conn
    |> render("show.html")
  end

  # Plug that assigns the tab based on a URL parameter or a default value to the connection
  @spec tab(Plug.Conn.t, list) :: Plug.Conn.t
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
    case Schedules.Repo.all(date: date, route: route.id, direction_id: direction_id) do
      {:error, _} -> []
      schedules -> schedules
    end
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

  # Plug that calls other plugs depending on which tab is currently set
  @spec tab_assigns(Plug.Conn.t, list) :: Plug.Conn.t
  defp tab_assigns(%Plug.Conn{assigns: %{tab: "timetable"}} = conn, _opts) do
    conn
    |> assign_trip_schedules
    |> call_plug(Site.ScheduleV2Controller.Offset)
  end
  defp tab_assigns(%Plug.Conn{assigns: %{tab: "trip-view"}} = conn, _opts) do
    conn = conn
    |> call_plug(Site.ScheduleV2Controller.Schedules)
    |> call_plug(Site.ScheduleV2Controller.StopTimes)
    |> call_plug(Site.ScheduleV2Controller.TripInfo)

    if conn.assigns.route.type == 2 do
      assign(conn, :zone_map, Map.new(conn.assigns.all_stops, &{&1.id, Zones.Repo.get(&1.id)}))
    else
      conn
    end
  end
  defp tab_assigns(%Plug.Conn{assigns: %{tab: "line"}} = conn, _opts) do
    conn
    |> call_plug(Site.ScheduleV2Controller.HoursOfOperation)
    |> call_plug(Site.ScheduleV2Controller.Holidays)
    |> call_plug(Site.ScheduleV2Controller.Line)
  end
end
