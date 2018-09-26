defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  import Util.AsyncAssign

  plug SiteWeb.Plugs.TransitNearMe
  plug SiteWeb.Plugs.RecommendedRoutes

  def index(conn, _params) do
    conn
    |> async_assign_default(:news, &news/0, [])
    |> async_assign_default(:banner, &Content.Repo.banner/0)
    |> async_assign_default(:whats_happening_items, &whats_happening_items/0)
    |> async_assign_default(:all_alerts, fn -> Alerts.Repo.all(conn.assigns.date_time) end)
    |> assign(:pre_container_template, "_pre_container.html")
    |> assign(:post_container_template, "_post_container.html")
    |> await_assign_all_default()
    |> render("index.html")
  end

  defp news do
    [limit: 7]
    |> Content.Repo.news()
    |> Enum.take(7)
  end

  defp whats_happening_items do
    case Content.Repo.whats_happening() do
      [_, _, _ | _] = items -> Enum.take(items, 3)
      _ -> nil
    end
  end
end
