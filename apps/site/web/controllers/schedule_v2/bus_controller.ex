defmodule Site.ScheduleV2.BusController do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.Alerts
  plug Site.ScheduleController.Defaults
  plug Site.ScheduleController.Schedules
  plug Site.Plugs.ScheduleV2.Headsigns
  plug Site.Plugs.ScheduleV2.Trip
  plug Site.Plugs.ScheduleV2.AllStops
  plug Site.Plugs.ScheduleV2.DirectionNames
  plug Site.Plugs.ScheduleV2.DestinationStops


  def show(conn, params) do
    conn
    |> assign(:date_select, params["date_select"] == "true")
    |> assign(:route_type, 3)
    |> assign(:holidays, Holiday.Repo.holidays_in_month(conn.assigns[:date]))
    |> render("show.html")
  end

  def origin(conn, _params) do
    render(conn, "_origin_trip.html")
  end
end

