defmodule Site.ScheduleV2Controller.Core do
  @moduledoc """
  Core pipeline for schedules
  """
  use Plug.Builder

  plug Site.ScheduleV2Controller.DatePicker
  plug Site.ScheduleV2Controller.Defaults
  plug :all_alerts
  plug Site.Plugs.UpcomingAlerts
  plug Site.ScheduleV2Controller.AllStops
  plug Site.ScheduleV2Controller.OriginDestination
  plug Site.ScheduleV2Controller.ExcludedStops
  plug Site.ScheduleV2Controller.PreSelect
  plug Site.ScheduleV2Controller.VehicleLocations
  plug Site.ScheduleV2Controller.Predictions
  plug Site.ScheduleV2Controller.RouteBreadcrumbs

  defp all_alerts(%{assigns: %{route: %Routes.Route{id: route_id, type: route_type}}} = conn, _opts) do
    assign(conn, :all_alerts, Alerts.Repo.by_route_id_and_type(route_id, route_type))
  end
end
