defmodule Site.PageView do
  import Phoenix.HTML.Tag

  use Site.Web, :view

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

  def schedule_separator do
    content_tag :span, "|", aria_hidden: "true"
  end
end
