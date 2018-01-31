defmodule SiteWeb.ScheduleV2Controller.AllStops do
  @moduledoc "Fetch all the stops on a route and assign them as @all_stops"
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]
  alias SiteWeb.ScheduleV2Controller.ClosedStops

  @impl true
  def init([]), do: []

  @impl true
  def call(conn, []) do
    stops = get_all_stops(conn)
    assign_all_stops(conn, stops)
  end

  defp get_all_stops(%{assigns: %{all_stops: all_stops}}) do
    all_stops
  end
  defp get_all_stops(%{assigns: %{route: %{id: "Red" = route_id}, direction_id: direction_id, date: date}}) do
    route_id
    |> Stops.Repo.by_route(direction_id, date: date)
    |> add_wollaston(direction_id)
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

  defp add_wollaston(stops, direction_id) do
    Enum.flat_map(stops, &insert_wollaston_node(&1, direction_id))
  end

  defp insert_wollaston_node(%{id: "place-qnctr"} = stop, 0), do: [ClosedStops.wollaston_stop(stop), stop]
  defp insert_wollaston_node(%{id: "place-nqncy"} = stop, 1), do: [ClosedStops.wollaston_stop(stop), stop]
  defp insert_wollaston_node(stop, _direction_id), do: [stop]
end
