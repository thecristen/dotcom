defmodule Site.ScheduleV2Controller.Core do
  @moduledoc """
  Core pipeline for schedules
  """
  use Plug.Builder
  import Site.ControllerHelpers, only: [call_plug: 2, assign_all_alerts: 2]

  plug :schedule_pipeline_setup
  plug :schedule_pipeline_with_direction
  plug Site.ScheduleV2Controller.OriginDestination
  plug Site.ScheduleV2Controller.ExcludedStops
  plug Site.ScheduleV2Controller.PreSelect
  plug Site.ScheduleV2Controller.VehicleLocations
  plug Site.ScheduleV2Controller.Predictions
  plug Site.ScheduleV2Controller.VehicleTooltips

  defp schedule_pipeline_setup(conn, _opts) do
    conn
    |> call_plug(Site.ScheduleV2Controller.DatePicker)
    |> call_plug(Site.ScheduleV2Controller.Defaults)
    |> call_plug(Site.ScheduleV2Controller.RouteBreadcrumbs)
  end

  defp schedule_pipeline_with_direction(conn, _opts) do
    conn
    |> assign_all_alerts([])
    |> call_plug(Site.Plugs.UpcomingAlerts)
    |> call_plug(Site.ScheduleV2Controller.AllStops)
  end
end
