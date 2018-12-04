defmodule SiteWeb.ProjectController do
  use SiteWeb, :controller
  @breadcrumb_base "Transforming the T"
  alias Content.Repo
  alias Plug.Conn

  def index(conn, _) do
    project_teasers = [type: "project", items_per_page: 50]
      |> Repo.teasers()
      |> sort_by_date()

    featured_project_teasers = [type: "project", sticky: 1, items_per_page: 5]
      |> Repo.teasers()
      |> sort_by_date()

    render conn, "index.html", %{
      breadcrumbs: [Breadcrumb.build(@breadcrumb_base)],
      project_teasers: project_teasers,
      featured_project_teasers: featured_project_teasers,
    }
  end

  @spec sort_by_date([Content.Teaser.t]) :: [Content.Teaser.t]
  defp sort_by_date(teasers) do
    Enum.sort(teasers, fn (%{date: d1}, %{date: d2}) ->
      {d1.year, d1.month, d1.day} >= {d2.year, d2.month, d2.day}
    end)
  end

  def show(%Plug.Conn{} = conn, _) do
    conn.request_path
    |> Repo.get_page(conn.query_params)
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
    |> Repo.get_page(conn.query_params)
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
    case Repo.get_page(update.project_url) do
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
  def get_events_async(id), do: fn -> Repo.events(project_id: id) end

  @spec get_updates_async(integer) :: (() -> [Content.Project.t])
  def get_updates_async(id), do: fn -> Repo.project_updates(project_id: id) end
end
