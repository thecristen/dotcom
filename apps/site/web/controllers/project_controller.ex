defmodule Site.ProjectController do
  use Site.Web, :controller

  def index(conn, _) do
    projects = Content.Repo.projects()
    render conn, "index.html", projects: projects
  end

  def show(conn, %{"id" => id}) do
    project = Content.Repo.project!(id)
    updates = Content.Repo.project_updates([project_id: id])
    meetings = Content.Repo.events([project_id: id])
    render conn, "show.html", project: project, updates: updates, meetings: meetings
  end

  def project_update(conn, %{"project_id" => project_id, "id" => id}) do
    project = Content.Repo.project!(project_id)
    update = Content.Repo.project_update!(id)
    render conn, "update.html", project: project, update: update
  end
end
