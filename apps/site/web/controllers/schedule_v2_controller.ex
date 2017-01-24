defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.Plugs.Holidays
  plug Site.Plugs.Alerts
  plug Site.ScheduleController.Defaults
  plug Site.ScheduleV2.Defaults
  plug Site.ScheduleController.DestinationStops
  plug Site.ScheduleController.Schedules
  plug Site.ScheduleV2Controller.Predictions
  plug Site.ScheduleController.Headsigns
  plug Site.ScheduleController.AllStops
  plug Site.ScheduleController.DirectionNames
  plug Site.ScheduleV2.TripInfo
  plug Site.ScheduleV2Controller.VehicleLocations

  def show(%Plug.Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, params) do
    conn
    |> assign(:tab, Map.get(params, "tab", "timetable"))
    |> assign(:schedule_template, "_commuter.html")
    |> tab_assigns()
    |> render("show.html")
  end
  def show(conn, _) do
    conn
    |> assign(:schedule_template, "_default_schedule.html")
    |> render("show.html")
  end

  defp assign_trip_schedules(conn) do
    timetable_schedules = timetable_schedules(conn)
    all_schedules = all_schedules(timetable_schedules)
    trip_schedules = Map.new(timetable_schedules, & {{&1.trip.id, &1.stop.id}, &1})

    conn
    |> assign(:timetable_schedules, timetable_schedules)
    |> assign(:all_schedules, all_schedules)
    |> assign(:trip_schedules, trip_schedules)
  end

  defp timetable_schedules(%{assigns: %{date: date, route: route, direction_id: direction_id}}) do
    Schedules.Repo.all(date: date, route: route.id, direction_id: direction_id)
  end

  defp all_schedules(timetable_schedules) do
    Enum.uniq_by(timetable_schedules, & &1.trip)
  end

  defp tab_assigns(%Plug.Conn{assigns: %{tab: "trip-view"}} = conn) do
    conn
    |> Site.ScheduleController.Schedules.call([])
    |> Site.ScheduleController.DirectionNames.call([])
    |> Site.ScheduleController.DestinationStops.call([])
    |> Site.ScheduleV2Controller.Predictions.call(Site.ScheduleV2Controller.Predictions.init([]))
  end
  defp tab_assigns(conn) do
    conn
    |> assign_trip_schedules
    |> Site.ScheduleV2Controller.Offset.call([])
    |> Site.Plugs.Alerts.call(Site.Plugs.Alerts.init([]))
    |> Site.ScheduleV2Controller.VehicleLocations.call(Site.ScheduleV2Controller.VehicleLocations.init([]))
  end
end
