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
    [project, updates, events] = [get_project(id), get_updates(id), get_events(id)]
    |> Enum.map(&Task.async/1)
    |> Enum.map(&Task.await/1)

    do_show(project, updates, events, conn)
  end

  @spec do_show(Content.Project.t | :not_found, [Content.ProjectUpdate.t], [Content.Event.t], Conn.t) :: Conn.t
  defp do_show(:not_found, _, _, conn), do: check_cms_or_404(conn)
  defp do_show(project, updates, events, conn) do
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
    [project, update] = [get_project(project_id), get_update(id)]
    |> Enum.map(&Task.async/1)
    |> Enum.map(&Task.await/1)

    do_show_project_update(project, update, conn)
  end

  @spec do_show_project_update(Content.Project.t | :not_found, Content.ProjectUpdate.t | :not_found, Conn.t) :: Conn.t
  defp do_show_project_update(:not_found, _, conn), do: check_cms_or_404(conn)
  defp do_show_project_update(_, :not_found, conn), do: check_cms_or_404(conn)
  defp do_show_project_update(project, update, conn) do
    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index)),
      Breadcrumb.build(project.title, project_path(conn, :show, project.id)),
      Breadcrumb.build(update.title)]

    render conn, "update.html", breadcrumbs: breadcrumbs, update: update, narrow_template: true
  end

  @spec get_project(String.t) :: (() -> Content.Project.t | no_return)
  defp get_project(id), do: fn -> Content.Repo.project(id) end

  @spec get_events(String.t) :: (() -> [Content.Event.t])
  defp get_events(id) do
    fn -> Content.Repo.events(project_id: id) end
  end

  @spec get_updates(String.t) :: (() -> [Content.Project.t])
  defp get_updates(id), do: fn -> Content.Repo.project_updates(project_id: id) end

  @spec get_update(String.t) :: (() -> Content.ProjectUpdate.t | no_return)
  defp get_update(id), do: fn -> Content.Repo.project_update(id) end
end
