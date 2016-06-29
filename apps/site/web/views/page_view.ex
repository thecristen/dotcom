defmodule Site.PageView do
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

  def clean_route_name(name) do
    name
    |> String.replace_suffix(" Line", "")
    |> String.replace("/", "/​") # slash replaced with a slash with a ZERO
                                # WIDTH SPACE afer
  end
end
