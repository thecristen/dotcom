defmodule SiteWeb.ProjectController do
  use SiteWeb, :controller
  @breadcrumb_base "Transforming the T"
  alias Plug.Conn

  def index(conn, _) do
    projects = Content.Repo.projects()
    featured_projects = Enum.filter(projects, & &1.featured)

    render(conn, "index.html", %{
      breadcrumbs: [Breadcrumb.build(@breadcrumb_base)],
      projects: projects,
      featured_projects: featured_projects,
    })
  end

  def show(conn, params) do
    params
    |> best_cms_path(conn.request_path)
    |> Content.Repo.get_page(conn.query_params)
    |> do_show(conn)
  end

  defp do_show(%Content.Project{} = project, conn), do: show_project(conn, project)
  defp do_show({:error, {:redirect, path}}, conn), do: redirect conn, to: path
  defp do_show(_404_or_mismatch, conn), do: render_404(conn)

  @spec show_project(Conn.t, Content.Project.t) :: Conn.t
  def show_project(conn, project) do
    [updates, events] = Util.async_with_timeout(
      [get_updates_async(project.id), get_events_async(project.id)],
      nil)

    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index)),
      Breadcrumb.build(project.title)]

    {past_events, upcoming_events} = Enum.split_with(events, &Content.Event.past?(&1, conn.assigns.date_time))

    render conn, "show.html", %{
      breadcrumbs: breadcrumbs,
      project: project,
      updates: updates,
      past_events: past_events,
      upcoming_events: upcoming_events,
      narrow_template: true
    }
  end

  def project_update(conn, params) do
    params
    |> best_cms_path(conn.request_path)
    |> Content.Repo.get_page(conn.query_params)
    |> do_project_update(conn)
  end

  defp do_project_update(%Content.ProjectUpdate{} = update, conn), do: show_project_update(conn, update)
  defp do_project_update({:error, {:redirect, path}}, conn), do: redirect conn, to: path
  defp do_project_update(_404_or_mismatch, conn), do: render_404(conn)

  @spec show_project_update(Conn.t, Content.ProjectUpdate.t) :: Conn.t
  def show_project_update(%Conn{} = conn, %Content.ProjectUpdate{} = update) do

    %Content.Project{} = project = case Content.Repo.get_page("/node/#{update.project_id}") do
      {:error, {:redirect, project_alias}} -> Content.Repo.get_page(project_alias)
      %Content.Project{} = project -> project
    end

    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index, [])),
      Breadcrumb.build(project.title, project_path(conn, :show, project)),
      Breadcrumb.build(update.title)]

    render conn, "update.html", breadcrumbs: breadcrumbs, update: update, narrow_template: true
  end

  @spec get_events_async(integer) :: (() -> [Content.Event.t])
  def get_events_async(id), do: fn -> Content.Repo.events(project_id: id) end

  @spec get_updates_async(integer) :: (() -> [Content.Project.t])
  def get_updates_async(id), do: fn -> Content.Repo.project_updates(project_id: id) end
end
