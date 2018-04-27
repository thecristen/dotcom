defmodule SiteWeb.ContentController do
  use SiteWeb, :controller
  require Logger

  @generic_page_types [
    Content.BasicPage,
    Content.Person,
    Content.LandingPage,
    Content.Redirect
  ]

  @routed_page_types [
    Content.Event,
    Content.NewsEntry,
    Content.Project,
    Content.ProjectUpdate,
  ]

  @spec page(Plug.Conn.t, map) :: Plug.Conn.t
  def page(%Plug.Conn{request_path: path, query_params: query_params} = conn, _params) do
    path
    |> Content.Repo.get_page(query_params)
    |> handle_page_response(conn)
  end

  @spec handle_page_response(Content.Page.t | {:error, Content.CMS.error}, Plug.Conn.t) :: Plug.Conn.t
  defp handle_page_response(%{__struct__: struct} = page, conn)
  when struct in @routed_page_types do
    # If these content types reach this point with a 200, something is wrong with their path alias
    # (the type-specific route controller is not being invoked due to the path not matching).
    case struct do
      Content.NewsEntry -> SiteWeb.NewsEntryController.show_news_entry(conn, page)
      Content.Event -> SiteWeb.EventController.show_event(conn, page)
      Content.Project -> SiteWeb.ProjectController.show_project(conn, page)
      Content.ProjectUpdate -> SiteWeb.ProjectController.show_project_update(conn, page)
    end
  end
  defp handle_page_response(%{__struct__: struct} = page, conn)
  when struct in @generic_page_types do
    conn
    |> put_layout({SiteWeb.LayoutView, :app})
    |> render_page(page)
  end
  defp handle_page_response({:error, {:redirect, status, opts}}, conn) do
    conn
    |> put_status(status)
    |> redirect(opts)
  end
  defp handle_page_response({:error, :timeout}, conn) do
    conn
    |> put_status(503)
    |> render(SiteWeb.ErrorView, "crash.html", [])
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
  defp render_page(conn, %Content.LandingPage{} = page) do
    conn
    |> assign(:breadcrumbs, page.breadcrumbs)
    |> assign(:page, page)
    |> assign(:pre_container_template, "landing_page.html")
    |> render(SiteWeb.ContentView, "empty.html", [])
  end
  defp render_page(conn, %Content.Person{} = person) do
    conn
    |> assign(:breadcrumbs, [Breadcrumb.build("People"), Breadcrumb.build(person.name)])
    |> render(SiteWeb.ContentView, "person.html", person: person)
  end
  defp render_page(conn, %Content.Redirect{link: link}) do
    redirect conn, external: link.url
  end

  defp no_sidebar?(%Content.BasicPage{sidebar_menu: nil}), do: true
  defp no_sidebar?(_), do: false
end
