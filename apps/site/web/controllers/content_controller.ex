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

  defp render_page(conn, %Content.BasicPage{} = page) do
    conn
    |> assign(:metadata, %{})
    |> assign(:breadcrumbs, [page.title])
    |> assign(:page, page)
    |> render(Site.ContentView, "page.html")
  end
  defp render_page(conn, %Content.ProjectUpdate{} = page) do
    conn
    |> assign(:metadata, %{})
    |> assign(:breadcrumbs, [page.title])
    |> assign(:page, page)
    |> render(Site.ContentView, "project_update.html")
  end
  defp render_page(conn, %Content.NewsEntry{} = page) do
    conn
    |> assign(:metadata, Content.MetaData.for_news_entry)
    |> assign(:page, page)
    |> render(Site.ContentView, "news_entry.html")
  end
  defp render_page(conn, _) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
end
