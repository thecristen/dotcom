defmodule Site.ContentController do
  use Site.Web, :controller
  require Logger

  @doc """

  Effectively a callback from Content.Router, this is responsible for
  doing the actual rendering.

  """
  @spec page(Plug.Conn.t, {:ok, Content.Page.t} | {:error, any}) :: Plug.Conn.t
  def page(conn, maybe_page) do
    conn
    |> put_layout({Site.LayoutView, :app})
    |> render_page(maybe_page)
  end

  defp render_page(conn, {:ok, []}) do
    render_page(conn, nil)
  end
  defp render_page(conn, {:ok, [page | _] = list}) do
    conn
    |> render(Site.ContentView, "#{page.type}_list.html", list: list)
  end
  defp render_page(conn, {:ok, page}) do
    conn
    |> render(Site.ContentView, "#{page.type}.html",
      breadcrumbs: [page.title],
      page: page)
  end
  defp render_page(conn, {:error, error}) do
    Logger.debug("error while fetching page: #{inspect error}")
    render_page(conn, nil)
  end
  defp render_page(conn, _) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
end
