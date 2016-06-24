defmodule Site.ScheduleController do
  use Site.Web, :controller

  def index(conn, %{"origin" => origin_id, "dest" => dest_id}) do
    conn
    |> Site.ScheduleController.Pairs.pairs(origin_id, dest_id)
  end

  def index(conn, %{"route" => "Green"}) do
    conn
    |> Site.ScheduleController.Green.green
  end

  def index(conn, %{"route" => route_id}) do
    conn
    |> Site.ScheduleController.Route.route(route_id)
  end
end
