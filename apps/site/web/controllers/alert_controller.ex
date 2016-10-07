defmodule Site.AlertController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Date
  plug Site.Plugs.Alerts

  @access_routes ["Elevator", "Escalator", "Lift"]
  |> Enum.map(&(%{id: &1, name: &1}))
  @access_route_map @access_routes
  |> Enum.reduce(%{}, fn route, map -> put_in map[route], [] end)

  def index(conn, _params) do
    conn
    |> redirect(to: alert_path(conn, :show, "subway"))
    |> halt
  end

  def show(conn, %{"id" => "subway"}) do
    render_routes(conn, [0, 1])
  end
  def show(conn, %{"id" => "commuter"}) do
    render_routes(conn, 2)
  end
  def show(conn, %{"id" => "bus"}) do
    render_routes(conn, 3)
  end
  def show(conn, %{"id" => "ferry"}) do
    render_routes(conn, 4)
  end
  def show(%{assigns: %{all_alerts: all_alerts}} = conn, %{"id" => "access"}) do
    conn
    |> render_route_alerts(group_access_alerts(all_alerts))
  end
  def show(conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end

  def render_routes(%{assigns: %{all_alerts: all_alerts}} = conn, route_types) do
    route_alerts = route_types
    |> Routes.Repo.by_type
    |> Enum.map(&route_alerts(&1, all_alerts))

    render_route_alerts(conn, route_alerts)
  end

  def render_route_alerts(conn, route_alerts) do
    conn
    |> render("show.html",
    id: String.to_existing_atom(conn.params["id"]),
    route_alerts: route_alerts
    )
  end

  def route_alerts(%Routes.Route{} = route, alerts) do
    entity = %Alerts.InformedEntity{
      route_type: route.type,
      route: route.id
    }
    {route, Alerts.Match.match(alerts, entity)}
  end

  def group_access_alerts(alerts) do
    alerts
    |> Enum.filter(&(&1.effect_name == "Access Issue"))
    |> Enum.reverse
    |> Enum.reduce(@access_route_map, fn alert, map ->
      route = access_route(alert)
      update_in map[route], fn existing ->
        [alert | existing]
      end
    end)
  end

  defp access_route(%Alerts.Alert{header: header}) do
    # create a fake "Route" for grouping access alerts
    type = header
    |> String.splitter(" ")
    |> Enum.at(0)

    %{id: type, name: type}
  end
end
