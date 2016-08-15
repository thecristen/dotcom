defmodule Site.PageController do
  use Site.Web, :controller

  @announcement_template "_beta_announcement.html"

  def index(conn, _params) do
    conn
    |> async_assign(:grouped_routes, &grouped_routes/0)
    |> async_assign(:news, &news/0)
    |> assign(:announcement_template, @announcement_template)
    |> await_assign_all
    |> render("index.html")
  end

  defp news do
    News.Repo.all(limit: 3)
  end

  defp grouped_routes do
    Routes.Repo.all
    |> Routes.Group.group
  end
end
