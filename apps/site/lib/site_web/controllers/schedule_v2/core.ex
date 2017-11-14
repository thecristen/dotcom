defmodule SiteWeb.ScheduleV2Controller.Core do
  @moduledoc """
  Core pipeline for schedules
  """
  use Plug.Builder
  import SiteWeb.ControllerHelpers, only: [call_plug: 2, assign_all_alerts: 2]

  plug :schedule_pipeline_setup
  plug :schedule_pipeline_with_direction
  plug SiteWeb.ScheduleV2Controller.OriginDestination
  plug SiteWeb.ScheduleV2Controller.ExcludedStops
  plug SiteWeb.ScheduleV2Controller.PreSelect
  plug SiteWeb.ScheduleV2Controller.VehicleLocations
  plug SiteWeb.ScheduleV2Controller.Predictions
  plug SiteWeb.ScheduleV2Controller.VehicleTooltips

  defp schedule_pipeline_setup(conn, _opts) do
    conn
    |> call_plug(SiteWeb.ScheduleV2Controller.DatePicker)
    |> call_plug(SiteWeb.ScheduleV2Controller.Defaults)
    |> call_plug(SiteWeb.ScheduleV2Controller.RouteBreadcrumbs)
  end

  defp schedule_pipeline_with_direction(conn, _opts) do
    conn
    |> assign_all_alerts([])
    |> call_plug(SiteWeb.Plugs.UpcomingAlerts)
    |> call_plug(SiteWeb.ScheduleV2Controller.AllStops)
  end
end
