defmodule Site.ViewHelpers.RouteLink do
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  import Phoenix.HTML.Link
  import Site.Router.Helpers
  import Site.ViewHelpers, only: [fa: 1, clean_route_name: 1]
  import Util

  @doc """
  HTML for a Route link.  If additional options are passed, they are
  passed to the schedule_path helper.
  """
  def route_link(conn, route, opts \\ []) do
    opts = Keyword.put(opts, :route, route.id)
    {class_name, opts} = Keyword.pop(opts, :class, "")

    circle = route_circle(route.type, route.id)

    alert = alert_icon(conn, route)

    alert
    |> string_join(circle)
    |> string_join(clean_route_name(route.name))
    |> raw
    |> link(
      to: schedule_path(conn, :show, route.id, opts),
      class: Util.string_join("mode-group-btn", class_name))
  end

  def alert_icon(conn, route) do
    alerts = conn.assigns.alerts || []
    entity = %Alerts.InformedEntity{route_type: route.type, route: route.id}
    route_alerts = Alerts.Match.match(alerts, entity)

    do_alert_icon(route_alerts)
  end

  @doc "HTML for a route circle"
  def route_circle(route_type, route_id)
  def route_circle(route_type, route_id) when route_type in [0, 1] do
    "circle fa-color-subway-"
    |> Kernel.<>(String.downcase(route_id))
    |> fa()
    |> safe_to_string
  end
  def route_circle(_,_), do: ""

  defp do_alert_icon([]), do: ""
  defp do_alert_icon(_), do: Site.AlertView.tooltip() |> safe_to_string
end
