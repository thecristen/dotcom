defmodule Site.AlertController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Date
  plug Site.Plugs.Alerts

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  def show(conn, %{"id" => "subway"}) do
    render_routes(conn, [0, 1])
  end
  def show(conn, %{"id" => "commuter-rail"}) do
    render_routes(conn, 2)
  end
  def show(conn, %{"id" => "bus"}) do
    render_routes(conn, 3)
  end
  def show(conn, %{"id" => "boat"}) do
    render_routes(conn, 4)
  end

  def render_routes(%{assigns: %{all_alerts: all_alerts}} = conn, route_types) do
    route_alerts = route_types
    |> Routes.Repo.by_type
    |> Enum.map(&route_alerts(&1, all_alerts))

    conn
    |> render("show.html", route_alerts: route_alerts)
  end

  def route_alerts(%Routes.Route{} = route, alerts) do
    entity = %Alerts.InformedEntity{
      route_type: route.type,
      route: route.id
    }
    {route, Alerts.Match.match(alerts, entity)}
  end
end
