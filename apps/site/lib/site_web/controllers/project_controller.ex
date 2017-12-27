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

  def show(conn, %{"id" => id}) do
    [project, updates, events] = Util.async_with_timeout(
      [get_project(id), get_updates(id), get_events(id)],
      nil)
    case project do
      :not_found -> check_cms_or_404(conn)
      project -> show_project(conn, project, updates, events)
    end
  end

  @spec show_project(Conn.t, Content.Project.t, [Content.ProjectUpdate.t], [Content.Event.t]) :: Conn.t
  def show_project(conn, project, updates, events) do
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

  def project_update(conn, %{"project_id" => project_id, "id" => id}) do
    [project, update] = Util.async_with_timeout(
      [get_project(project_id), get_update(id)],
      nil)

    case {project, update} do
      {:not_found, _} -> check_cms_or_404(conn)
      {_, :not_found} -> check_cms_or_404(conn)
      {project, update} -> show_project_update(conn, project, update)
    end
  end

  @spec show_project_update(Conn.t, Content.Project.t, Content.ProjectUpdate.t) :: Conn.t
  def show_project_update(conn, project, update) do
    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index)),
      Breadcrumb.build(project.title, SiteWeb.ResourceLinkHelpers.show_path(:project, project.path_alias)),
      Breadcrumb.build(update.title)]

    render conn, "update.html", breadcrumbs: breadcrumbs, update: update, narrow_template: true
  end

  @spec get_project(String.t) :: (() -> Content.Project.t | no_return)
  def get_project(id), do: fn -> Content.Repo.project(id) end

  @spec get_events(String.t) :: (() -> [Content.Event.t])
  def get_events(id) do
    fn -> Content.Repo.events(project_id: id) end
  end

  @spec get_updates(String.t) :: (() -> [Content.Project.t])
  def get_updates(id), do: fn -> Content.Repo.project_updates(project_id: id) end

  @spec get_update(String.t) :: (() -> Content.ProjectUpdate.t | no_return)
  defp get_update(id), do: fn -> Content.Repo.project_update(id) end
end
