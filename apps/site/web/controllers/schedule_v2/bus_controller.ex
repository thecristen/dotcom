defmodule Site.ScheduleV2.BusController do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.ScheduleController.Defaults
  plug Site.ScheduleController.Schedules

  def show(conn, _params) do
    render(conn, "show.html")
  end

  def origin(conn, _params) do
    render(conn, "_origin_trip.html")
  end
end

