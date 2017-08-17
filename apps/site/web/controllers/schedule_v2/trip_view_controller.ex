defmodule Site.ScheduleV2Controller.TripViewController do
  @moduledoc """
  Plug builder for the tripView Schedule tab
  """
  use Site.Web, :controller
  alias Routes.Route

  plug Site.Plugs.Route
  plug :tab_name
  plug Site.ScheduleV2Controller.Core
  plug Site.ScheduleV2Controller.Schedules
  plug Site.ScheduleV2Controller.Journeys
  plug Site.ScheduleV2Controller.TripInfo
  plug :zone_map

  def show(conn, _) do
    render(conn, Site.ScheduleV2View, "show.html")
  end

  defp zone_map(%{assigns: %{route: %Route{type: 2}, all_stops: all_stops}} = conn, _) do
      assign(conn, :zone_map, Map.new(all_stops, &{&1.id, Zones.Repo.get(&1.id)}))
  end
  defp zone_map(conn, _), do: conn

  defp tab_name(conn, _), do: assign(conn, :tab, "trip-view")
end
