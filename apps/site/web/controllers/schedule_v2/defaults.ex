defmodule Site.ScheduleV2.Defaults do
  use Plug.Builder
  alias Plug.Conn
  alias Routes.Route

  plug :assign_date_select
  plug :assign_route_type

  def assign_date_select(conn, _) do
    assign(conn, :date_select, Map.get(conn.params, "date_select") == "true")
  end

  def assign_route_type(%Conn{assigns: %{route: %Route{type: type}}} = conn, _), do: assign conn, :route_type, type
end
