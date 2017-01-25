defmodule Site.ScheduleV2Controller.Defaults do
  @moduledoc """

  Responsible for assigning:
    headsigns:         %{0 => [String.t], 1 => [String.t]
    direction_id:      0 | 1
    origin:            %Stop{} | nil
    destination:       %Stop{} | nil
    show_date_select?: boolean
  """
  use Plug.Builder
  alias Plug.Conn
  alias Routes.Route
  import UrlHelpers
  import Phoenix.Controller, only: [redirect: 2]

  plug :assign_headsigns
  plug :assign_direction_id
  plug :assign_origin
  plug :assign_destination
  plug :assign_show_date_select

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

  def assign_headsigns(%Conn{assigns: %{route: %Route{id: route_id}}} = conn, _),
    do: assign(conn, :headsigns, Routes.Repo.headsigns(route_id))
  def assign_headsigns(conn, _), do: assign(conn, :headsigns, %{0 => [], 1 => []})

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

  def assign_direction_id(conn, _) do
    do_assign_direction_id(conn.query_params["direction_id"], conn)
  end

  defp do_assign_direction_id("0", conn), do: assign(conn, :direction_id, 0)
  defp do_assign_direction_id("1", conn), do: assign(conn, :direction_id, 1)
  defp do_assign_direction_id(_, conn), do: assign(conn, :direction_id, default_direction_id(conn))

  @doc """
  If there's no headsign for a direction, default to the other direction. Otherwise, default to
  inbound before 1:00pm and outbound afterwards.
  """
  def default_direction_id(%{assigns: %{headsigns: %{0 => []}}}), do: 1
  def default_direction_id(%{assigns: %{headsigns: %{1 => []}}}), do: 0
  def default_direction_id(conn) do
    if conn.assigns.date_time.hour <= 13, do: 1, else: 0
  end

  def assign_show_date_select(conn, _) do
    assign(conn, :show_date_select?, Map.get(conn.params, "date_select") == "true")
  end
end
