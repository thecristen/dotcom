defmodule Site.ScheduleController do
  use Site.Web, :controller

  defdelegate alerts(conn, params), to: Site.ScheduleController.Alerts

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

  def subway(conn, _params) do
    Site.ScheduleController.Modes.render(conn, Site.ScheduleController.Modes.Subway)
  end

  def bus(conn, _params) do
    Site.ScheduleController.Modes.render(conn, Site.ScheduleController.Modes.Bus)
  end

  def boat(conn, _params) do
    Site.ScheduleController.Modes.render(conn, Site.ScheduleController.Modes.Boat)
  end

  def commuter_rail(conn, _params) do
    Site.ScheduleController.Modes.render(conn, Site.ScheduleController.Modes.CommuterRail)
  end
end
