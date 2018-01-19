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
    case Integer.parse(id) do
      {int_id, ""} -> do_show(conn, Content.Repo.project(int_id))
      _ -> do_show(conn, Content.Repo.get_page(conn.request_path, conn.query_params))
    end
  end

  defp do_show(conn, maybe_project) do
    case maybe_project do
      :not_found -> check_cms_or_404(conn)
      project -> show_project(conn, project)
    end
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

    render conn, "show.html", %{
      breadcrumbs: breadcrumbs,
      project: project,
      updates: updates,
      past_events: past_events,
      upcoming_events: upcoming_events,
      narrow_template: true
    }
  end

  def project_update(conn, %{"update_id" => update_id}) do
    case Integer.parse(update_id) do
      {int_id, ""} -> do_project_update(conn, Content.Repo.project_update(int_id))
      _ -> do_project_update(conn, Content.Repo.get_page(conn.request_path, conn.query_params))
    end
  end

  defp do_project_update(conn, maybe_update) do
    case maybe_update do
      :not_found -> check_cms_or_404(conn)
      update -> show_project_update(conn, update)
    end
  end

  @spec show_project_update(Conn.t, Content.ProjectUpdate.t) :: Conn.t
  def show_project_update(conn, update) do

    project = Content.Repo.project(update.project_id)

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
