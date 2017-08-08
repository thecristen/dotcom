defmodule Site.SearchController do
  use Site.Web, :controller

  @doc """
  """
  def index(conn, _params) do
    conn
    |> render("index.html", breadcrumbs: ["Search Results"])
  end
end
