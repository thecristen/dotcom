defmodule Site.ModeController do
  use Site.Web, :controller

  alias Site.Mode

  defdelegate subway(conn, params), to: Mode.SubwayController, as: :index
  defdelegate bus(conn, params), to: Mode.BusController, as: :index
  defdelegate boat(conn, params), to: Mode.BoatController, as: :index
  defdelegate commuter_rail(conn, params), to: Mode.CommuterRailController, as: :index

  def index(conn, %{"route" => route_id} = params) when is_binary(route_id) do
    # redirect from old /schedules?route=ID to new /schedules/ID
    new_path = schedule_path(conn, :show, route_id, Map.delete(params, "route"))
    redirect conn, to: new_path
  end

  def index(conn, _params) do
    conn
    |> render("index.html",
      datetime: Util.now,
      grouped_routes: Routes.Repo.all |> Routes.Group.group,
      breadcrumbs: ["Schedules & Maps"]
    )
  end
end
