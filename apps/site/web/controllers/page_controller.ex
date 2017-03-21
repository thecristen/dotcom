defmodule Site.PageController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.Alerts, upcoming?: false
  plug Site.Plugs.TransitNearMe

  def index(conn, params) do
    conn
    |> assign(:grouped_routes, filtered_grouped_routes([:subway, :bus]))
    |> async_assign(:news, &news/0)
    |> await_assign_all
    |> assign_tnm_column_groups
    |> assign(:pre_container_template, "_pre_container.html")
    |> assign(:post_container_template, "_post_container.html")
    |> whats_happening_banner(params)
    |> render("index.html")
  end

  defp news do
    News.Repo.all(limit: 4)
  end

  defp whats_happening_banner(conn, %{"whats_happening_banner" => _}) do
    assign(conn, :whats_happening_banner, true)
  end
  defp whats_happening_banner(conn, _params), do: conn
end
