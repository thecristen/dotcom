defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  import Util.AsyncAssign

  plug SiteWeb.Plugs.TransitNearMe
  plug SiteWeb.Plugs.RecommendedRoutes

  def index(conn, _params) do
    {promoted, remainder} = whats_happening_items()
    conn
    |> async_assign_default(:news, &news/0, [])
    |> async_assign_default(:banner, &Content.Repo.banner/0)
    |> async_assign_default(:promoted_items, fn -> promoted end)
    |> async_assign_default(:whats_happening_items, fn -> remainder end)
    |> async_assign_default(:all_alerts, fn -> Alerts.Repo.all(conn.assigns.date_time) end)
    |> assign(:pre_container_template, "_pre_container.html")
    |> assign(:post_container_template, "_post_container.html")
    |> await_assign_all_default()
    |> render("index.html")
  end

  defp news do
    [limit: 5]
    |> Content.Repo.news()
    |> Enum.take(5)
  end

  defp whats_happening_items do
    split_whats_happening(Content.Repo.whats_happening())
  end

  def split_whats_happening(whats_happening) do
    case whats_happening do
      [_, _, _, _, _ | _] = items ->
        {first_two, rest} = Enum.split(items, 2)
        {first_two, Enum.take(rest, 3)}
      [_, _ | _] = items -> {Enum.take(items, 2), []}
      _ -> {nil, nil}
    end
  end
end
