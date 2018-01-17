defmodule SiteWeb.ContentController do
  use SiteWeb, :controller
  require Logger

  alias SiteWeb.EventController
  alias SiteWeb.EventView
  alias SiteWeb.NewsEntryController
  alias SiteWeb.NewsEntryView
  alias SiteWeb.ProjectController
  alias SiteWeb.ProjectView

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

  @page_types [
    Content.BasicPage,
    Content.Event,
    Content.NewsEntry,
    Content.LandingPage,
    Content.Project,
    Content.ProjectUpdate,
    Content.Person,
    Content.Redirect
  ]

  @spec page(Plug.Conn.t, map) :: Plug.Conn.t
  def page(%Plug.Conn{request_path: path, query_params: query_params} = conn, _params) do
    path
    |> Content.Repo.get_page(query_params)
    |> handle_page_response(conn)
  end

  @spec handle_page_response(Content.Page.t | {:error, Content.CMS.error}, Plug.Conn.t) :: Plug.Conn.t
  defp handle_page_response(%{__struct__: struct} = page, conn) when struct in @page_types do
    conn
    |> put_layout({SiteWeb.LayoutView, :app})
    |> render_page(page)
  end
  defp handle_page_response({:error, {:redirect, path}}, conn) do
    redirect conn, to: path
  end
  defp handle_page_response({:error, :not_found}, %Plug.Conn{path_info: [top | _]} = conn) when top in @old_site_paths do
    redirect conn, to: redirect_path(conn, :show, conn.path_info, conn.query_params)
  end
  defp handle_page_response({:error, :not_found}, conn) do
    render_404(conn)
  end

  @spec render_page(Plug.Conn.t, Content.Page.t) :: Plug.Conn.t
  defp render_page(conn, %Content.BasicPage{} = page) do
    conn
    |> assign(:breadcrumbs, page.breadcrumbs)
    |> assign(:page, page)
    |> assign(:narrow_template, no_sidebar?(page))
    |> render(SiteWeb.ContentView, "page.html", conn: conn)
  end
  defp render_page(conn, %Content.Event{} = event) do
    conn
    |> put_view(EventView)
    |> EventController.show_event(event)
  end
  defp render_page(conn, %Content.LandingPage{} = page) do
    conn
    |> assign(:breadcrumbs, page.breadcrumbs)
    |> assign(:page, page)
    |> assign(:pre_container_template, "landing_page.html")
    |> render(SiteWeb.ContentView, "empty.html", [])
  end
  defp render_page(conn, %Content.NewsEntry{} = news_entry) do
    conn
    |> put_view(NewsEntryView)
    |> NewsEntryController.show_news_entry(news_entry)
  end
  defp render_page(conn, %Content.Person{} = person) do
    conn
    |> assign(:breadcrumbs, [Breadcrumb.build("People"), Breadcrumb.build(person.name)])
    |> render("person.html", person: person)
  end
  defp render_page(conn, %Content.Project{} = project) do
    conn
    |> put_view(ProjectView)
    |> ProjectController.show_project(project)
  end
  defp render_page(conn, %Content.ProjectUpdate{} = project_update) do
    conn
    |> put_view(ProjectView)
    |> ProjectController.show_project_update(project_update)
  end
  defp render_page(conn, %Content.Redirect{link: link}) do
    redirect conn, external: link.url
  end

  defp no_sidebar?(%Content.BasicPage{sidebar_menu: nil}), do: true
  defp no_sidebar?(_), do: false
end
