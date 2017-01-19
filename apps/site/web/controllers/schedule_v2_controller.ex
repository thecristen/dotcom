defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller


  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
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

  def show(conn, _) do
    conn
    |> render("show.html")
  end
end
