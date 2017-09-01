defmodule Site.ProjectController do
  use Site.Web, :controller
  @breadcrumb_base "Transforming the T"

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
    [project, updates, meetings] = [get_project(id), get_updates(id), get_meetings(id)]
    |> Enum.map(&Task.async/1)
    |> Enum.map(&Task.await/1)

    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index)),
      Breadcrumb.build(project.title)]

    render conn, "show.html", %{
      breadcrumbs: breadcrumbs,
      project: project,
      updates: updates,
      meetings: meetings
    }
  end

  def project_update(conn, %{"project_id" => project_id, "id" => id}) do
    [project, update] = [get_project(project_id), get_update(id)]
    |> Enum.map(&Task.async/1)
    |> Enum.map(&Task.await/1)

    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index)),
      Breadcrumb.build(project.title, project_path(conn, :show, project_id)),
      Breadcrumb.build(update.title)]

    render conn, "update.html", breadcrumbs: breadcrumbs, update: update
  end

  @spec get_project(String.t) :: (() -> Content.Project.t | no_return)
  defp get_project(id), do: fn -> Content.Repo.project!(id) end

  @spec get_meetings(String.t) :: (() -> [Content.Event.t])
  defp get_meetings(id), do: fn -> Content.Repo.events([project_id: id]) end

  @spec get_updates(String.t) :: (() -> [Content.Project.t])
  defp get_updates(id), do: fn -> Content.Repo.project_updates([project_id: id]) end

  @spec get_update(String.t) :: (() -> Content.ProjectUpdate.t | no_return)
  defp get_update(id), do: fn -> Content.Repo.project_update!(id) end
end
