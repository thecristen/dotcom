defmodule Site.ScheduleController.AllStops do
  @moduledoc "Fetch all the stops on a route and assign them as @all_stops"

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{route: %{id: "Red" = route_id}}} = conn, []) do
    conn
    |> assign(:all_stops, Enum.uniq_by(get_all_stops(conn, route_id), &(&1.id)))
  end
  def call(%{assigns: %{route: %{id: route_id}}} = conn, []) do
    conn
    |> assign(:all_stops, get_all_stops(conn, route_id))
  end
  def call(conn, []) do
    conn
    |> assign(:all_stops, [])
  end

  defp get_all_stops(conn, route_id) do
    Schedules.Repo.stops(
      route_id,
      direction_id: conn.assigns[:direction_id]
    )
  end
end
