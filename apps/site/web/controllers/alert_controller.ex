defmodule Site.AlertController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug :all_routes
  plug :all_alerts
  plug Site.Plugs.UpcomingAlerts

  @access_route_ids ["Elevator", "Escalator", "Lift"]
  @access_routes @access_route_ids
  |> Enum.map(&(%Routes.Route{id: &1, name: &1}))
  @access_route_map @access_routes
  |> Enum.reduce(%{}, fn route, map -> put_in map[route], [] end)

  def index(conn, _params) do
    conn
    |> redirect(to: alert_path(conn, :show, "subway"))
    |> halt
  end

  def show(%{assigns: %{all_alerts: all_alerts}} = conn, %{"id" => "access"}) do
    conn
    |> render_route_alerts(group_access_alerts(all_alerts))
  end
  def show(conn, %{"id" => mode})
  when mode in ["subway", "commuter_rail", "bus", "ferry"] do
    render_routes(conn)
  end
  def show(conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end

  def render_routes(%{assigns: %{all_alerts: all_alerts, all_routes: all_routes}} = conn) do
    render_route_alerts(conn, Enum.map(all_routes, &route_alerts(&1, all_alerts)))
  end

  def render_route_alerts(%{params: %{"id" => id}} = conn, route_alerts) do
    route_alerts = route_alerts
    |> Enum.reject(&match?({_, []}, &1))

    conn
    |> render("show.html",
    id: String.to_existing_atom(id),
    route_alerts: route_alerts,
    breadcrumbs: ["Alerts"]
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
    # create a fake "Route" for grouping access alerts. We want it to be
    # something from @access_route_types, so we find the first one that
    # matches the header
    type = @access_route_ids
    |> Enum.find(&String.contains?(header, &1))

    # fail if we didn't find anything
    case type do
      type when is_binary(type) ->
        %Routes.Route{id: type, name: type}
    end
  end

  defp all_routes(%{params: %{"id" => "subway"}} = conn, _opts), do: do_all_routes(conn, [0,1])
  defp all_routes(%{params: %{"id" => "commuter_rail"}} = conn, _opts), do: do_all_routes(conn, 2)
  defp all_routes(%{params: %{"id" => "bus"}} = conn, _opts), do: do_all_routes(conn, 3)
  defp all_routes(%{params: %{"id" => "ferry"}} = conn, _opts), do: do_all_routes(conn, 4)
  defp all_routes(conn, _opts), do: conn

  defp do_all_routes(conn, route_types) do
    assign(conn, :all_routes, Routes.Repo.by_type(route_types))
  end

  defp all_alerts(%{params: %{"id" => "subway"}} = conn, _opts), do: do_all_alerts(conn, [0,1])
  defp all_alerts(%{params: %{"id" => "commuter_rail"}} = conn, _opts), do: do_all_alerts(conn, [2])
  defp all_alerts(%{params: %{"id" => "bus"}} = conn, _opts), do: do_all_alerts(conn, [3])
  defp all_alerts(%{params: %{"id" => "ferry"}} = conn, _opts), do: do_all_alerts(conn, [4])
  defp all_alerts(%{params: %{"id" => "access"}} = conn, _opts) do
    assign(conn, :all_alerts, Alerts.Repo.all())
  end
  defp all_alerts(conn, _opts) do
    conn
  end

  defp do_all_alerts(conn, types) do
    alerts = Alerts.Repo.by_route_types(types)
    assign(conn, :all_alerts, alerts)
  end
end
