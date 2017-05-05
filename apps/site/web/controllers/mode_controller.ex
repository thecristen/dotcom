defmodule Site.ModeController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.DateTime

  alias Site.Mode

  defdelegate subway(conn, params), to: Mode.SubwayController, as: :index
  defdelegate bus(conn, params), to: Mode.BusController, as: :index
  defdelegate ferry(conn, params), to: Mode.FerryController, as: :index
  defdelegate commuter_rail(conn, params), to: Mode.CommuterRailController, as: :index

  def index(conn, %{"route" => route_id} = params) when is_binary(route_id) do
    # redirect from old /schedules?route=ID to new /schedules/ID
    new_path = schedule_path(conn, :show, route_id, Map.delete(params, "route"))
    redirect conn, to: new_path
  end

  def index(conn, _params) do
    grouped_routes = filtered_grouped_routes([:bus])
    conn
    |> async_assign(:all_alerts, fn -> grouped_routes |> get_grouped_route_ids() |> Alerts.Repo.by_route_ids() end)
    |> assign(:grouped_routes, grouped_routes)
    |> assign(:breadcrumbs, ["Schedules & Maps"])
    |> assign(:include_ride, true)
    |> await_assign_all()
    |> render("index.html")
  end
end
