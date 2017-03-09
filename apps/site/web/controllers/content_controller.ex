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

  defp render_page(%{request_path: "/events"} = conn, {:ok, list}) do
    conn
    |> render(Site.ContentView, "event_list.html", list: list)
  end
  defp render_page(conn, {:ok, page}) do
    conn
    |> assign(:metadata, Content.MetaData.for(page.type))
    |> assign(:breadcrumbs, [page.title])
    |> assign(:page, page)
    |> render(Site.ContentView, "#{page.type}.html")
  end
  defp render_page(conn, {:error, error}) do
    _ = Logger.debug("error while fetching page: #{inspect error}")
    render_page(conn, nil)
  end
  defp render_page(conn, _) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
end
