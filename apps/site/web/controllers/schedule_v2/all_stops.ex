defmodule Site.ScheduleV2Controller.AllStops do
  @moduledoc "Fetch all the stops on a route and assign them as @all_stops"

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%Plug.Conn{assigns: assigns} = conn, []) do
    stops = get_all_stops(assigns.route.id, assigns.direction_id, assigns.date)
    conn
    |> assign(:all_stops, stops)
  end

  defp get_all_stops(route_id, direction_id, date) do
    Stops.Repo.by_route(route_id, direction_id, date: date)
  end
end
