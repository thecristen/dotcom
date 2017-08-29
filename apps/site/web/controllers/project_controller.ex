defmodule Site.ProjectController do
  use Site.Web, :controller

  def index(conn, _) do
    projects = Content.Repo.projects()
    render conn, "index.html", projects: projects
  end
end
