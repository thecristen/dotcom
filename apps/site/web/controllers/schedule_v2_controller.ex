defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller
  alias Routes.Route

  plug Site.Plugs.Route
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime

  @spec show(Plug.Conn.t, map) :: Phoenix.HTML.Safe.t
  def show(%{assigns: %{route: %Route{type: 2, id: route_id}}} = conn, _params) do
    conn
    |> redirect(to: timetable_path(conn, :show, route_id))
    |> halt()
  end
  def show(%{assigns: %{route: %Route{id: route_id}}} = conn, _params) do
    conn
    |> redirect(to: trip_view_path(conn, :show, route_id))
    |> halt()
  end
end
