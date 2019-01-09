defmodule SiteWeb.AlertController do
  use SiteWeb, :controller
  alias Alerts.{Alert, InformedEntity, Match}
  alias Stops.Stop

  plug(:routes)
  plug(:alerts)
  plug(SiteWeb.Plugs.AlertsByTimeframe)
  plug(SiteWeb.Plug.Mticket)

  @valid_ids ~w(subway commuter-rail bus ferry access)s

  def index(conn, _params) do
    conn
    |> redirect(to: alert_path(conn, :show, "subway"))
    |> halt
  end

  def show(%{assigns: %{alerts: alerts}} = conn, %{"id" => "access"}) do
    conn
    |> render_alert_groups(group_access_alerts(alerts))
  end

  def show(conn, %{"id" => mode}) when mode in @valid_ids do
    render_routes(conn)
  end

  def show(conn, _params) do
    check_cms_or_404(conn)
  end

  def render_routes(%{assigns: %{alerts: alerts, routes: routes}} = conn) do
    render_alert_groups(conn, Enum.map(routes, &route_alerts(&1, alerts)))
  end

  def render_alert_groups(%{params: %{"id" => id}} = conn, route_alerts) do
    conn
    |> assign(
      :meta_description,
      "Live service alerts for all MBTA transportation modes, including subway, bus, Commuter Rail, and ferry. " <>
        "Updates on delays, construction, elevator outages, and more."
    )
    |> render(
      "show.html",
      id: id_to_atom(id),
      alert_groups: route_alerts |> Enum.reject(&match?({_, []}, &1)),
      breadcrumbs: [Breadcrumb.build("Alerts")]
    )
  end

  def route_alerts(%Routes.Route{} = route, alerts) do
    entity = %InformedEntity{
      route_type: route.type,
      route: route.id
    }

    {route, Match.match(alerts, entity)}
  end

  def group_access_alerts(alerts) do
    access_effects = Alert.access_alert_types() |> Keyword.keys() |> MapSet.new()

    alerts
    |> Enum.filter(&MapSet.member?(access_effects, &1.effect))
    |> Enum.reduce(%{}, &group_access_alerts_by_stop/2)
    |> Enum.map(fn {stop_id, alerts} ->
      stop = Stops.Repo.get(stop_id)
      {stop, alerts}
    end)
    |> Enum.sort_by(fn {stop, _} -> stop.name end)
  end

  defp group_access_alerts_by_stop(%Alert{} = alert, acc) do
    alert.informed_entity.stop
    |> MapSet.to_list()
    |> Enum.reduce(acc, &do_group_access_alerts_by_stop(&1, alert, &2))
  end

  defp do_group_access_alerts_by_stop(stop_id, alert, acc) do
    # stop_ids are sometimes child stops.
    # Fetch the stop_id from the repo to get the parent id.
    case Stops.Repo.get(stop_id) do
      %Stop{id: parent_stop_id} ->
        Map.update(acc, parent_stop_id, MapSet.new([alert]), &MapSet.put(&1, alert))

      _ ->
        acc
    end
  end

  defp routes(%{params: %{"id" => "subway"}} = conn, _opts), do: do_routes(conn, [0, 1])
  defp routes(%{params: %{"id" => "commuter-rail"}} = conn, _opts), do: do_routes(conn, 2)
  defp routes(%{params: %{"id" => "bus"}} = conn, _opts), do: do_routes(conn, 3)
  defp routes(%{params: %{"id" => "ferry"}} = conn, _opts), do: do_routes(conn, 4)
  defp routes(conn, _opts), do: conn

  defp do_routes(conn, route_types) do
    assign(conn, :routes, Routes.Repo.by_type(route_types))
  end

  defp alerts(%{params: %{"id" => id}} = conn, _opts) when id in @valid_ids do
    alerts = Alerts.Repo.all(conn.assigns.date_time)
    assign(conn, :alerts, alerts)
  end

  defp alerts(conn, _opts) do
    conn
  end

  defp id_to_atom("commuter-rail"), do: :commuter_rail
  defp id_to_atom(id), do: String.to_existing_atom(id)
end
