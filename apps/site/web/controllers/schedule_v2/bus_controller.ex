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

  # This may be good to have as a behavior when doing integration for all modes
  @route_type 3


  def show(conn, params) do
    conn
    |> assign(:date_select, params["date_select"] == "true")
    |> assign(:route_type, @route_type)
    |> render("show.html")
  end

  def origin(conn, _params) do
    render(conn, "_origin_trip.html")
  end

  def origin_destination(conn, _params) do
    render(conn, "_origin_destination_trip.html")
  end
end

