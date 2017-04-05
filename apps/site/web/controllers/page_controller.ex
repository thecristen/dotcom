defmodule Site.PageController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.Alerts, upcoming?: false
  plug Site.Plugs.TransitNearMe

  def index(conn, _params) do
    conn
    |> assign(:grouped_routes, filtered_grouped_routes([:subway, :bus]))
    |> async_assign(:news, &news/0)
    |> await_assign_all
    |> assign_tnm_column_groups
    |> assign(:pre_container_template, "_pre_container.html")
    |> assign(:post_container_template, "_post_container.html")
    |> important_notice
    |> whats_happening_items
    |> render("index.html")
  end

  defp news do
    News.Repo.all(limit: 4)
  end

  defp important_notice(conn) do
    notice = case Content.Repo.important_notices() do
      [notice] -> notice
      _ -> nil
    end
    assign(conn, :important_notice, notice)
  end

  defp whats_happening_items(conn) do
    items = case Content.Repo.whats_happening() do
      [_, _, _] = items -> items
      _ -> nil
    end

    assign(conn, :whats_happening_items, items)
  end
end
