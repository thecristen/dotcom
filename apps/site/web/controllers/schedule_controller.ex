defmodule Site.ScheduleController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Alerts

  def show(%{query_params: %{"route" => new_route_id}} = conn,
    %{"route" => old_route_id} = params) when new_route_id != old_route_id do
    new_path = schedule_path(conn, :show, new_route_id, Map.delete(params, "route"))
    redirect conn, to: new_path
  end
  def show(conn, %{"route" => route_id, "origin" => origin_id, "dest" => dest_id})
    when origin_id != "" and dest_id != "" do
    conn
    |> Site.ScheduleController.Pairs.pairs(route_id, origin_id, dest_id)
  end

  def show(conn, %{"route" => route_id}) do
    conn
    |> Site.ScheduleController.Route.route(route_id)
  end
end
