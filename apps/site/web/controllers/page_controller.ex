defmodule Site.PageController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.TransitNearMe

  def index(conn, _params) do
    grouped_routes = filtered_grouped_routes([:subway, :bus])
    conn
    |> async_assign(:news, &news/0)
    |> async_assign(:important_notice, &Content.Repo.important_notice/0)
    |> async_assign(:whats_happening_items, &whats_happening_items/0)
    |> async_assign(:all_alerts, fn -> grouped_routes |> get_grouped_route_ids() |> Alerts.Repo.by_route_ids() end)
    |> assign_tnm_column_groups
    |> assign(:pre_container_template, "_pre_container.html")
    |> assign(:post_container_template, "_post_container.html")
    |> assign(:grouped_routes, grouped_routes)
    |> await_assign_all()
    |> render("index.html")
  end

  defp news do
    News.Repo.all(limit: 4)
  end

  defp whats_happening_items do
    case Content.Repo.whats_happening() do
      [_, _, _] = items -> items
      _ -> nil
    end
  end
end
