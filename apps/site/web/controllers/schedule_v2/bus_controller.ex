defmodule Site.ScheduleV2.BusController do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.Holidays
  plug Site.Plugs.Alerts
  plug Site.ScheduleController.Defaults
  plug Site.ScheduleController.Schedules
  plug Site.ScheduleController.Headsigns
  plug Site.ScheduleController.AllStops


  def show(conn, params) do
    conn
    |> assign(:date_select, params["date_select"] == "true")
    |> assign(:route_type, 3)
    |> render("show.html")
  end

  def origin(conn, _params) do
    render(conn, "_origin_trip.html")
  end
end

