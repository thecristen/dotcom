defmodule Site.ContentController do
  use Site.Web, :controller
  require Logger

  @old_site_paths [
    "about_the_mbta",
    "business_center",
    "customer_support",
    "fares_and_passes",
    "rider_tools",
    "riding_the_t",
    "schedules_and_maps",
    "transitpolice",
  ]

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
    |> assign(:breadcrumbs, page.breadcrumbs)
    |> assign(:page, page)
    |> render(Site.ContentView, "page.html")
  end
  defp render_page(conn, %Content.LandingPage{} = page) do
    conn
    |> assign(:breadcrumbs, page.breadcrumbs)
    |> assign(:page, page)
    |> assign(:pre_container_template, "landing_page.html")
    |> render(Site.ContentView, "empty.html")
  end
  defp render_page(conn, %Content.Redirect{link: link}) do
    redirect conn, external: link.url
  end
  defp render_page(%{path_info: [top | _]} = conn, _) when top in @old_site_paths do
    redirect conn, to: redirect_path(conn, :show, conn.path_info, conn.query_params)
  end
  defp render_page(conn, _) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
end
