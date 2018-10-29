defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  import Util.AsyncAssign
  import UrlHelpers, only: [build_utm_params: 3, build_utm_url: 2]

  plug SiteWeb.Plugs.TransitNearMe
  plug SiteWeb.Plugs.RecommendedRoutes

  def index(conn, _params) do
    {promoted, remainder} = whats_happening_items()
    banner = banner()
    conn
    |> async_assign_default(:news, &news/0, [])
    |> async_assign_default(:banner, fn -> banner end)
    |> async_assign_default(:promoted_items, fn -> promoted end)
    |> async_assign_default(:whats_happening_items, fn -> remainder end)
    |> async_assign_default(:all_alerts, fn -> Alerts.Repo.all(conn.assigns.date_time) end)
    |> await_assign_all_default()
    |> render("index.html")
  end

  defp banner do
    case Content.Repo.banner() do
      nil -> nil
      banner -> add_utm_url("banner", banner, "homepage")
    end
  end

  defp news do
    [limit: 5]
    |> Content.Repo.news()
    |> Enum.take(5)
    |> Enum.map(&add_utm_url("news", &1, "homepage"))
  end

  defp whats_happening_items do
    Content.Repo.whats_happening()
    |> split_whats_happening()
    |> split_add_utm_url()
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

  defp split_add_utm_url({nil, nil}) do
    {nil, nil}
  end
  defp split_add_utm_url({promoted, rest}) do
    promoted = Enum.map(promoted, &add_utm_url("whats-happening", &1, "homepage"))
    rest = Enum.map(rest, &add_utm_url("whats-happening-secondary", &1, "homepage"))
    {promoted, rest}
  end

  def add_utm_url("news", %Content.NewsEntry{} = item, source) do
    Map.put(item, :utm_url, build_utm_url(news_entry_path(nil, :show, item), build_utm_params("news", item, source)))
  end
  def add_utm_url(type, item, source) do
    Map.put(item, :utm_url, build_utm_url(item.link.url, build_utm_params(type, item, source)))
  end
end
