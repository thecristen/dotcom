defmodule Site.ScheduleV2Controller.OriginDestination do
  @moduledoc """
  Assigns origin and destination to either a Stops.Stop.t or nil. Checks if the requested stops are valid
  for the route and direction (i.e., that they're on the line and accessible in the given direction).
  """

  use Plug.Builder
  alias Plug.Conn
  import UrlHelpers
  import Phoenix.Controller, only: [redirect: 2]

  plug :assign_origin
  plug :assign_destination

  def assign_origin(%Conn{query_params: %{"origin" => _}} = conn, _) do
    conn = assign_stop(conn, :origin)
    if conn.assigns.origin == nil do
      conn
      |> redirect(to: update_url(conn, origin: nil, destination: nil))
      |> halt
    else
      conn
    end
  end
  def assign_origin(conn, _) do
    assign(conn, :origin, nil)
  end

  def assign_destination(%Conn{query_params: %{"destination" => _}} = conn, _) do
    conn = assign_stop(conn, :destination)
    if conn.assigns.destination == nil do
      conn
      |> redirect(to: update_url(conn, destination: nil))
      |> halt
    else
      conn
    end
  end
  def assign_destination(conn, _) do
    assign(conn, :destination, nil)
  end

  def assign_stop(conn, key) do
    stop_id = Map.get(conn.query_params, Atom.to_string(key))
    if Schedules.Repo.stop_exists_on_route?(stop_id, conn.assigns.route.id, conn.assigns.direction_id) do
      do_assign_stop(stop_id, conn, key)
    else
      conn
      |> assign(key, nil)
    end
  end

  defp do_assign_stop(stop_id, conn, key), do: assign(conn, key, Stops.Repo.get(stop_id))
end
