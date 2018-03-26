defmodule SiteWeb.SearchV2Controller do
  use SiteWeb, :controller

  @typep routes_fn :: (() -> [Routes.Route.t])
  @typep stops_fn :: (() -> [Stops.Stop.t])

  def index(conn, _params) do
    if Laboratory.enabled?(conn, :search_v2) do
      all_alerts = Alerts.Repo.all(conn.assigns.date_time)

      conn
      |> assign(:requires_google_maps?, true)
      |> assign(:stops_with_alerts, stops_with_alerts(all_alerts))
      |> assign(:routes_with_alerts, routes_with_alerts(all_alerts))
      |> render("index.html")
    else
      render_404(conn)
    end
  end

  defp stops_by_route_fn do
    Enum.concat([Stops.Repo.by_route_type(:subway),
                 Stops.Repo.by_route_type(:commuter_rail),
                 Stops.Repo.by_route_type(:bus),
                 Stops.Repo.by_route_type(:ferry)])
  end

  @spec stops_with_alerts([Alerts.Alert.t], routes_fn) :: [Stops.Stop.t]
  def stops_with_alerts(alerts, stops_fn \\ &stops_by_route_fn/0) do
    stops_fn.()
    |> Enum.filter(&SiteWeb.StopView.has_alerts?(alerts, Util.today(), %Alerts.InformedEntity{stop: &1.id}))
    |> Enum.map(&(&1.id))
  end

  @spec routes_with_alerts([Alerts.Alert.t], stops_fn) :: [Routes.Route.t]
  def routes_with_alerts(alerts, routes_fn \\ &Routes.Repo.all/0) do
    routes_fn.()
    |> Enum.filter(&Site.Components.Buttons.ModeButtonList.has_alert?(&1, alerts, Util.now()))
    |> Enum.map(&(&1.id))
  end
end
