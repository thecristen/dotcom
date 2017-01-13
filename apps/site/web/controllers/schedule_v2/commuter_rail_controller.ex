defmodule Site.ScheduleV2.CommuterRailController do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.ScheduleController.Defaults
  plug Site.ScheduleController.Schedules
  plug Site.ScheduleController.AllStops
  plug Site.ScheduleV2Controller.Offset
  plug Site.ScheduleV2Controller.VehicleLocations

  def timetable(conn, _params) do
    conn
    |> assign_trip_schedules
    |> render("_timetable.html")
  end

  defp assign_trip_schedules(%Plug.Conn{assigns: %{all_schedules: all_schedules}} = conn) do
    trip_schedules = all_schedules
    |> Enum.flat_map(& Schedules.Repo.schedule_for_trip(&1.trip.id))
    |> Map.new(& {{&1.trip.id, &1.stop.id}, &1})

    assign(conn, :trip_schedules, trip_schedules)
  end
end
