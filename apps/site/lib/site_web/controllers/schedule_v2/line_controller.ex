defmodule SiteWeb.ScheduleV2Controller.LineController do
  use SiteWeb, :controller

  plug SiteWeb.Plugs.Route
  plug :tab_name
  plug SiteWeb.ScheduleV2Controller.RoutePdfs
  plug SiteWeb.ScheduleV2Controller.Defaults
  plug :all_alerts
  plug SiteWeb.Plugs.UpcomingAlerts
  plug SiteWeb.ScheduleV2Controller.AllStops
  plug SiteWeb.ScheduleV2Controller.RouteBreadcrumbs
  plug SiteWeb.ScheduleV2Controller.HoursOfOperation
  plug SiteWeb.ScheduleV2Controller.Holidays
  plug SiteWeb.ScheduleV2Controller.VehicleLocations
  plug SiteWeb.ScheduleV2Controller.Predictions
  plug SiteWeb.ScheduleV2Controller.VehicleTooltips
  plug SiteWeb.ScheduleV2Controller.Line
  plug :require_map

  def show(conn, _) do
    render(conn, SiteWeb.ScheduleV2View, "show.html", [])
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "line")

  defp all_alerts(conn, _), do: assign_all_alerts(conn, [])

  defp require_map(conn, _), do: assign(conn, :requires_google_maps?, true)
end
