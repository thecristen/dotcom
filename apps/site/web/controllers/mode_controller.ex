defmodule Site.ModeController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.Plugs.Alerts, upcoming?: false

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
    conn
    |> render("index.html",
      grouped_routes: filtered_grouped_routes([:bus]),
      breadcrumbs: ["Schedules & Maps"],
      include_ride: true
    )
  end
end
