defmodule SiteWeb.ContentController do
  use SiteWeb, :controller
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
  defp handle_page_response(%{__struct__: struct} = page, %{request_path: "/node/" <> _} = conn)
  when struct in @routed_page_types do
    # Routed pages types that don't have an alias should be re-routed to proper helper
    path = case struct do
      Content.NewsEntry -> news_entry_path(conn, :show, page)
      Content.Event -> event_path(conn, :show, page)
      Content.Project -> project_path(conn, :show, page)
      Content.ProjectUpdate -> project_update_path(conn, :project_update, page)
    end
    redirect conn, to: path
  end
  defp handle_page_response(%{__struct__: struct} = page, conn) when struct in @routed_page_types do
    # if these content types reach this point with a 200, something is wrong with their path or alias.
    # We want to return a 404 and log a warning to alert the team to investigate.
    _ = Logger.warn fn ->
      "[CMS] A request to #{conn.request_path} returned a #{inspect(struct)}, but #{conn.request_path}" <>
      " does not conform to front-end pattern for this content type.
      Got: #{inspect(page)}"
    end
    render_404(conn)
  end
  defp handle_page_response(%{__struct__: struct} = page, conn) when struct in @generic_page_types do
    conn
    |> put_layout({SiteWeb.LayoutView, :app})
    |> render_page(page)
  end
  defp handle_page_response({:error, {:redirect, status, path}}, conn) do
    conn
    |> put_status(status)
    |> redirect(to: path)
  end
  defp handle_page_response({:error, :not_found}, %Plug.Conn{path_info: [top | _]} = conn)
  when top in @old_site_paths do
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
    |> render("person.html", person: person)
  end
  defp render_page(conn, %Content.Redirect{link: link}) do
    redirect conn, external: link.url
  end

  defp no_sidebar?(%Content.BasicPage{sidebar_menu: nil}), do: true
  defp no_sidebar?(_), do: false
end
