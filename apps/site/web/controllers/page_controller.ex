defmodule Site.PageController do
  use Site.Web, :controller
  import Phoenix.HTML, only: [raw: 1]

  def index(conn, _params) do
    news = News.Repo.all(limit: 5)
    render conn, "index.html", %{
      news: news,
      news_image: news_image(news),
      grouped_routes: grouped_routes
    }
  end

  defp grouped_routes do
    Routes.Repo.all
    |> Routes.Group.group
  end

  defp news_image(news) do
    case news |> Enum.filter(&(&1.attributes["homepageicon"])) do
      [entry|_] ->
        raw entry.attributes["homepageicon"]
        |> String.replace("src=\"/", "src=\"//www.mbta.com/")
      _ ->
        nil
    end
  end
end
