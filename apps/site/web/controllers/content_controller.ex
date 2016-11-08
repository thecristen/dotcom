defmodule Site.ContentController do
  use Site.Web, :controller
  require Logger

  def page(conn, %{"url" => url_parts}) do
    path = url_parts
    |> Enum.join("/")

    conn
    |> render_content(Content.Repo.page(path))
  end

  defp render_content(conn, {:ok, %Content.Page{} = page}) do
    render(conn, "page.html",
      breadcrumbs: [page.title],
      page: page)
  end
  defp render_content(conn, {:error, error}) do
    Logger.debug("error while fetching page: #{inspect error}")
    render_content(conn, nil)
  end
  defp render_content(conn, _) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
end
