defmodule Site.ScheduleV2Controller.AllStops do
  @moduledoc "Fetch all the stops on a route and assign them as @all_stops"

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    stops = get_all_stops(conn)
    assign_all_stops(conn, stops)
  end

  defp get_all_stops(%{assigns: %{all_stops: all_stops}}) do
    all_stops
  end
  defp get_all_stops(%{assigns: assigns}) do
    Stops.Repo.by_route(assigns.route.id, assigns.direction_id, date: assigns.date)
  end

  defp assign_all_stops(conn, stops) when is_list(stops) do
    assign(conn, :all_stops, stops)
  end
  defp assign_all_stops(conn, {:error, error}) do
    conn
    |> assign(:all_stops, [])
    |> assign(:schedule_error, error)
  end
end
