defmodule Site.ScheduleV2.CommuterRailController do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.ScheduleV2.Defaults
  plug Site.Plugs.Holidays
  plug Site.ScheduleController.Defaults
  plug Site.ScheduleController.AllStops
  plug Site.ScheduleV2Controller.VehicleLocations
  plug Site.ScheduleController.Headsigns

  def show(conn, params) do
    conn
    |> assign(:tab, Map.get(params, "tab", "timetable"))
    |> tab_assigns()
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
  end
  defp tab_assigns(conn) do
    conn
    |> assign_trip_schedules
    |> Site.ScheduleV2Controller.Offset.call([])
    |> Site.Plugs.Alerts.call(Site.Plugs.Alerts.init([]))
  end
end
