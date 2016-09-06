defmodule Site.ScheduleController do
  use Site.Web, :controller

  alias Site.ScheduleController

  plug Site.Plugs.Route
  plug Site.Plugs.Alerts
  plug ScheduleController.Defaults
  plug ScheduleController.AllRoutes
  plug ScheduleController.AllStops
  plug ScheduleController.DestinationStops

  def show(%{query_params: %{"route" => new_route_id}} = conn,
    %{"route" => old_route_id} = params) when new_route_id != old_route_id do
    new_path = schedule_path(conn, :show, new_route_id, Map.delete(params, "route"))
    redirect conn, to: new_path
  end
  def show(conn, %{"origin" => origin_id, "dest" => dest_id})
    when origin_id != "" and dest_id != "" do
    conn
    |> ScheduleController.Pairs.pairs(origin_id, dest_id)
  end
  def show(conn, _params) do
    conn
    |> ScheduleController.Route.route
  end
end
