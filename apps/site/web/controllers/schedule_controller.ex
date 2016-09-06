defmodule Site.ScheduleController do
  use Site.Web, :controller

  def index(conn, %{"route" => route_id, "origin" => origin_id, "dest" => dest_id})
    when origin_id != "" and dest_id != "" do
    conn
    |> Site.ScheduleController.Pairs.pairs(route_id, origin_id, dest_id)
  end

  def index(conn, %{"route" => "Green"}) do
    conn
    |> Site.ScheduleController.Green.green
  end

  def index(conn, %{"route" => route_id}) do
    conn
    |> Site.ScheduleController.Route.route(route_id)
  end

  def index(conn, params) do
    conn
    |> Site.ModeController.index(params)
  end
end
