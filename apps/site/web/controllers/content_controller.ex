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

  def page(conn, _params) do
    maybe_page = Content.Repo.get_page(conn.request_path, conn.query_string)
    conn
    |> put_layout({Site.LayoutView, :app})
    |> render_page(maybe_page)
  end

  defp render_page(conn, %Content.BasicPage{} = page) do
    conn
    |> assign(:breadcrumbs, page.breadcrumbs)
    |> assign(:page, page)
    |> assign(:narrow_template, true)
    |> render(Site.ContentView, "page.html")
  end
  defp render_page(conn, %Content.Event{id: id}) do
    redirect conn, to: event_path(conn, :show, id)
  end
  defp render_page(conn, %Content.LandingPage{} = page) do
    conn
    |> assign(:breadcrumbs, page.breadcrumbs)
    |> assign(:page, page)
    |> assign(:pre_container_template, "landing_page.html")
    |> render(Site.ContentView, "empty.html")
  end
  defp render_page(conn, %Content.NewsEntry{id: id}) do
    redirect conn, to: news_entry_path(conn, :show, id)
  end
  defp render_page(conn, %Content.Person{id: id}) do
    redirect conn, to: person_path(conn, :show, id)
  end
  defp render_page(conn, %Content.Project{id: id}) do
    redirect conn, to: project_path(conn, :show, id)
  end
  defp render_page(conn, %Content.ProjectUpdate{id: id, project_id: project_id}) do
    redirect conn, to: project_path(conn, :project_update, project_id, id)
  end
  defp render_page(conn, %Content.Redirect{link: link}) do
    redirect conn, external: link.url
  end
  defp render_page(%{path_info: [top | _]} = conn, _) when top in @old_site_paths do
    redirect conn, to: redirect_path(conn, :show, conn.path_info, conn.query_params)
  end
  defp render_page(conn, _) do
    render_404(conn)
  end
end
