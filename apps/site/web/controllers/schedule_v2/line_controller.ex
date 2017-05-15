defmodule Site.ScheduleV2Controller.LineController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug :tab_name
  plug Site.ScheduleV2Controller.Defaults
  plug :assign_all_alerts
  plug Site.ScheduleV2Controller.AllStops
  plug Site.ScheduleV2Controller.RouteBreadcrumbs
  plug Site.ScheduleV2Controller.HoursOfOperation
  plug Site.ScheduleV2Controller.Holidays
  plug Site.ScheduleV2Controller.Line

  def show(conn, _) do
    render(conn, Site.ScheduleV2View, "show.html")
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "line")

  defp assign_all_alerts(conn, _), do: Site.ControllerHelpers.assign_all_alerts(conn, [])
end
