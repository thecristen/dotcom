defmodule Site.ScheduleV2.CommuterRailController do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.ScheduleController.Defaults
  plug :assign_trip_schedules
  plug Site.ScheduleController.AllStops
  plug Site.ScheduleV2Controller.Offset
  plug Site.ScheduleV2Controller.VehicleLocations
  plug Site.Plugs.Alerts

  def timetable(conn, _params) do
    conn
    |> render("_timetable.html")
  end

  defp assign_trip_schedules(conn, _) do
    timetable_schedules = timetable_schedules(conn)
    all_schedules = all_schedules(timetable_schedules)
    trip_schedules = 
      Map.new(timetable_schedules, & {{&1.trip.id, &1.stop.id}, &1})

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
      
end
