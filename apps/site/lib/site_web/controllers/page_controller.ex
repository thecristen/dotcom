defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  import Util.AsyncAssign

  plug SiteWeb.Plugs.TransitNearMe

  def index(conn, _params) do
    conn
    |> async_assign_default(:news, &news/0, [])
    |> async_assign_default(:important_notice, &Content.Repo.important_notice/0)
    |> async_assign_default(:whats_happening_items, &whats_happening_items/0)
    |> async_assign_default(:all_alerts, fn -> Alerts.Repo.all(conn.assigns.date_time) end)
    |> assign(:pre_container_template, "_pre_container.html")
    |> assign(:post_container_template, "_post_container.html")
    |> assign(:grouped_routes, filtered_grouped_routes([:bus]))
    |> await_assign_all_default()
    |> render("index.html")
  end

  defp news do
    Enum.take(Content.Repo.news(limit: 4), 4)
  end

  defp whats_happening_items do
    case Content.Repo.whats_happening() do
      [_, _, _] = items -> items
      _ -> nil
    end
  end
end
