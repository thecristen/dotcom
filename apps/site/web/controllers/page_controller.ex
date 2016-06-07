defmodule Site.PageController do
  use Site.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", %{
      news: News.Repo.all(limit: 5),
      alerts: Alerts.Repo.all,
      grouped_routes: grouped_routes
    }
  end

  defp grouped_routes do
    Routes.Repo.all
    |> Routes.Group.group
  end
end
