defmodule Site.PageView do
  use Site.Web, :view

  def render_alert_list(route_type_description, routes, alerts, max_route_count \\ :infinity) do
    routes_with_alerts = routes
    |> Enum.filter(&(has_alerts?(&1, alerts)))

    {additional, routes_with_alerts} = limit_alert_display(routes_with_alerts, max_route_count)

    render "_alert_list.html", %{
      route_type_description: route_type_description,
      routes_with_alerts: routes_with_alerts,
      additional: additional
    }
  end

  def has_alerts?(route, alerts) do
    entity = %Alerts.InformedEntity{
      route_type: route.type,
      route: route.id
    }
    matched = alerts
    |> Alerts.Match.match(entity)

    case matched do
      [] -> false
      #[_] -> false
      _ -> true
    end
  end

  def limit_alert_display(routes_with_alerts, :infinity) do
    {0, routes_with_alerts}
  end
  def limit_alert_display(routes_with_alerts, count) when length(routes_with_alerts) > count do
    {length(routes_with_alerts) - count, routes_with_alerts |> Enum.take(count)}
  end
  def limit_alert_display(routes_with_alerts, _) do
    {0, routes_with_alerts}
  end

  def clean_route_name(name) do
    name
    |> String.replace_suffix(" Line", "")
    |> String.replace("/", "/​") # slash replaced with a slash with a ZERO
                                # WIDTH SPACE afer
  end
end
