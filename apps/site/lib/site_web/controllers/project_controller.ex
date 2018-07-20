defmodule SiteWeb.ProjectController do
  use SiteWeb, :controller
  @breadcrumb_base "Transforming the T"
  alias Plug.Conn

  def index(conn, _) do
    projects = Content.Repo.projects()
    featured_projects = Enum.filter(projects, & &1.featured)

    render conn, "index.html", %{
      breadcrumbs: [Breadcrumb.build(@breadcrumb_base)],
      projects: projects,
      featured_projects: featured_projects,
    }
  end

  def show(%Plug.Conn{} = conn, _) do
    conn.request_path
    |> Content.Repo.get_page(conn.query_params)
    |> do_show(conn)
  end

  defp do_show(%Content.Project{} = project, conn) do
    show_project(conn, project)
  end
  defp do_show({:error, {:redirect, status, opts}}, conn) do
    conn
    |> put_status(status)
    |> redirect(opts)
  end
  defp do_show(_404_or_mismatch, conn) do
    render_404(conn)
  end

  @spec show_project(Conn.t, Content.Project.t) :: Conn.t
  def show_project(conn, project) do
    [updates, events] = Util.async_with_timeout(
      [get_updates_async(project.id), get_events_async(project.id)],
      nil)

    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index)),
      Breadcrumb.build(project.title)]

    {past_events, upcoming_events} = Enum.split_with(events, &Content.Event.past?(&1, conn.assigns.date_time))

    render conn, SiteWeb.ProjectView, "show.html", %{
      breadcrumbs: breadcrumbs,
      project: project,
      updates: updates,
      past_events: past_events,
      upcoming_events: upcoming_events,
    }
  end

  def project_update(%Plug.Conn{} = conn, _params) do
    conn.request_path
    |> Content.Repo.get_page(conn.query_params)
    |> do_project_update(conn)
  end

  defp do_project_update(%Content.ProjectUpdate{} = update, conn) do
    show_project_update(conn, update)
  end
  defp do_project_update({:error, {:redirect, status, opts}}, conn) do
    conn
    |> put_status(status)
    |> redirect(opts)
  end
  defp do_project_update(_404_or_mismatch, conn) do
    render_404(conn)
  end

  @spec show_project_update(Conn.t, Content.ProjectUpdate.t) :: Conn.t
  def show_project_update(%Conn{} = conn, %Content.ProjectUpdate{} = update) do
    case Content.Repo.get_page(update.project_url) do
      %Content.Project{} = project ->
        breadcrumbs = [
          Breadcrumb.build(@breadcrumb_base, project_path(conn, :index, [])),
          Breadcrumb.build(project.title, project_path(conn, :show, project)),
          Breadcrumb.build(update.title)]

        render conn, SiteWeb.ProjectView, "update.html", %{
          breadcrumbs: breadcrumbs,
          update: update,
        }
      {:error, {:redirect, _, [to: path]}} ->
        show_project_update(conn, %{update | project_url: path})
      _ ->
        render_404(conn)
    end

  end

  @spec get_events_async(integer) :: (() -> [Content.Event.t])
  def get_events_async(id), do: fn -> Content.Repo.events(project_id: id) end

  @spec get_updates_async(integer) :: (() -> [Content.Project.t])
  def get_updates_async(id), do: fn -> Content.Repo.project_updates(project_id: id) end
end
