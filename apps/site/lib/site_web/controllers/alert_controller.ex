defmodule SiteWeb.AlertController do
  use SiteWeb, :controller

  plug(:all_routes)
  plug(:all_alerts)
  plug(SiteWeb.Plugs.UpcomingAlerts)
  plug(SiteWeb.Plug.Mticket)

  @valid_ids ~w(subway commuter-rail bus ferry access)s

  def index(conn, _params) do
    conn
    |> redirect(to: alert_path(conn, :show, "subway"))
    |> halt
  end

  def show(%{assigns: %{all_alerts: all_alerts}} = conn, %{"id" => "access"}) do
    conn
    |> render_route_alerts(group_access_alerts(all_alerts))
  end

  def show(conn, %{"id" => mode}) when mode in @valid_ids do
    render_routes(conn)
  end

  def show(conn, _params) do
    check_cms_or_404(conn)
  end

  def render_routes(%{assigns: %{all_alerts: all_alerts, all_routes: all_routes}} = conn) do
    render_route_alerts(conn, Enum.map(all_routes, &route_alerts(&1, all_alerts)))
  end

  def render_route_alerts(%{params: %{"id" => id}} = conn, route_alerts) do
    conn
    |> assign(
      :meta_description,
      "Live service alerts for all MBTA transportation modes, including subway, bus, Commuter Rail, and ferry. " <>
        "Updates on delays, construction, elevator outages, and more."
    )
    |> render(
      "show.html",
      id: id_to_atom(id),
      route_alerts: route_alerts |> Enum.reject(&match?({_, []}, &1)),
      breadcrumbs: [Breadcrumb.build("Alerts")]
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
    Enum.reduce(
      Alerts.Alert.access_alert_types(),
      %{},
      &group_access_alerts_by_type(alerts, &1, &2)
    )
  end

  defp group_access_alerts_by_type(alerts, {type, name}, accumulator) do
    route = %Routes.Route{id: name, name: name}
    filtered_alerts = Enum.filter(alerts, &(&1.effect == type))

    Map.put(accumulator, route, filtered_alerts)
  end

  defp all_routes(%{params: %{"id" => "subway"}} = conn, _opts), do: do_all_routes(conn, [0, 1])
  defp all_routes(%{params: %{"id" => "commuter-rail"}} = conn, _opts), do: do_all_routes(conn, 2)
  defp all_routes(%{params: %{"id" => "bus"}} = conn, _opts), do: do_all_routes(conn, 3)
  defp all_routes(%{params: %{"id" => "ferry"}} = conn, _opts), do: do_all_routes(conn, 4)
  defp all_routes(conn, _opts), do: conn

  defp do_all_routes(conn, route_types) do
    assign(conn, :all_routes, Routes.Repo.by_type(route_types))
  end

  defp all_alerts(%{params: %{"id" => id}} = conn, _opts) when id in @valid_ids do
    assign(conn, :all_alerts, Alerts.Repo.all(conn.assigns.date_time))
  end

  defp all_alerts(conn, _opts) do
    conn
  end

  defp id_to_atom("commuter-rail"), do: :commuter_rail
  defp id_to_atom(id), do: String.to_existing_atom(id)
end
