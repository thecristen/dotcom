defmodule SiteWeb.ScheduleController.LineController do
  use SiteWeb, :controller

  plug SiteWeb.Plugs.Route
  plug SiteWeb.Plugs.DateInRating
  plug :tab_name
  plug SiteWeb.ScheduleController.RoutePdfs
  plug SiteWeb.ScheduleController.Defaults
  plug :all_alerts
  plug SiteWeb.Plugs.UpcomingAlerts
  plug SiteWeb.ScheduleController.AllStops
  plug SiteWeb.ScheduleController.RouteBreadcrumbs
  plug SiteWeb.ScheduleController.HoursOfOperation
  plug SiteWeb.ScheduleController.Holidays
  plug SiteWeb.ScheduleController.VehicleLocations
  plug SiteWeb.ScheduleController.Predictions
  plug SiteWeb.ScheduleController.VehicleTooltips
  plug SiteWeb.ScheduleController.Line
  plug :require_map
  plug :channel_id

  def show(conn, _) do
    render(conn, SiteWeb.ScheduleView, "show.html", [])
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "line")

  defp all_alerts(conn, _), do: assign_all_alerts(conn, [])

  defp require_map(conn, _), do: assign(conn, :requires_google_maps?, true)

  defp channel_id(conn, _) do
    assign(conn, :channel, "vehicles:#{conn.assigns.route.id}:#{conn.assigns.direction_id}")
  end
end
