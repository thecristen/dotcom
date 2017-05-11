defmodule Site.ScheduleV2Controller.TripView do
  @moduledoc """
  Plug builder for the tripView Schedule tab
  """
  use Plug.Builder
  alias Routes.Route

  plug Site.ScheduleV2Controller.Core
  plug Site.ScheduleV2Controller.Schedules
  plug Site.ScheduleV2Controller.StopTimes
  plug Site.ScheduleV2Controller.TripInfo
  plug :zone_map

  defp zone_map(%{assigns: %{route: %Route{type: 2}, all_stops: all_stops}} = conn, _) do
      assign(conn, :zone_map, Map.new(all_stops, &{&1.id, Zones.Repo.get(&1.id)}))
  end
  defp zone_map(conn, _), do: conn
end
