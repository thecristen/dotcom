defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  import Util.AsyncAssign
  alias Content.{Banner, NewsEntry, WhatsHappeningItem}

  plug SiteWeb.Plugs.TransitNearMe
  plug SiteWeb.Plugs.RecentlyVisited

  def index(conn, _params) do
    {promoted, remainder} = whats_happening_items()
    banner = banner()
    conn
    |> assign(
      :meta_description,
      "Public transit in the Greater Boston region. Routes, schedules, trip planner, fares, " <>
      "service alerts, real-time updates, and general information."
    )
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
      banner -> add_utm_url(banner)
    end
  end

  defp news do
    [limit: 5]
    |> Content.Repo.news()
    |> Enum.take(5)
    |> Enum.map(&add_utm_url/1)
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
    {
      Enum.map(promoted, &add_utm_url(&1, true)),
      Enum.map(rest, &add_utm_url/1)
    }
  end

  def add_utm_url(%{} = item, promoted? \\ false) do
    url = UrlHelpers.build_utm_url(
      item,
      type: utm_type(item, promoted?),
      term: utm_term(item),
      source: "homepage"
    )
    %{item | utm_url: url}
  end

  defp utm_type(%Banner{}, _), do: "banner"
  defp utm_type(%NewsEntry{}, _), do: "news"
  defp utm_type(%WhatsHappeningItem{}, true), do: "whats-happening"
  defp utm_type(%WhatsHappeningItem{}, false), do: "whats-happening-secondary"

  defp utm_term(%{mode: mode}), do: mode
  defp utm_term(_), do: "null"
end
