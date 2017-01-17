defmodule Site.ScheduleV2.Defaults do
  use Plug.Builder
  alias Plug.Conn
  alias Routes.Route

  plug :assign_date_select
  plug :assign_route_type
  plug :assign_show_all_trips

  def assign_date_select(conn, _) do
    assign(conn, :date_select, Map.get(conn.params, "date_select") == "true")
  end

  def assign_show_all_trips(conn, _) do
    assign(conn, :show_all_trips, Map.get(conn.params, "show_all_trips") == "true")
  end

  def assign_route_type(%Conn{assigns: %{route: %Route{type: type}}} = conn, _), do: assign conn, :route_type, type
end
