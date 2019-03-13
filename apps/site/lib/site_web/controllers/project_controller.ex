defmodule SiteWeb.ProjectController do
  use SiteWeb, :controller

  alias Content.Repo
  alias Plug.Conn

  @breadcrumb_base "Transforming the T"

  def index(conn, _) do
    project_teasers_fn = fn ->
      [type: "project", items_per_page: 50]
      |> Repo.teasers()
      |> sort_by_date()
    end

    featured_project_teasers_fn = fn ->
      [type: "project", sticky: 1, items_per_page: 5]
      |> Repo.teasers()
      |> sort_by_date()
    end

    conn
    |> async_assign_default(:project_teasers, project_teasers_fn, [])
    |> async_assign_default(:featured_project_teasers, featured_project_teasers_fn, [])
    |> assign(:breadcrumbs, [Breadcrumb.build(@breadcrumb_base)])
    |> await_assign_all_default(__MODULE__)
    |> render("index.html")
  end

  @spec sort_by_date([Content.Teaser.t()]) :: [Content.Teaser.t()]
  defp sort_by_date(teasers) do
    Enum.sort(teasers, fn %{date: d1}, %{date: d2} ->
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

  @spec show_project(Conn.t(), Content.Project.t()) :: Conn.t()
  def show_project(conn, project) do
    [updates, events] =
      Util.async_with_timeout(
        [get_updates_async(project.id), get_events_async(project.id)],
        [],
        __MODULE__
      )

    breadcrumbs = [
      Breadcrumb.build(@breadcrumb_base, project_path(conn, :index)),
      Breadcrumb.build(project.title)
    ]

    {past_events, upcoming_events} =
      Enum.split_with(events, &Content.Event.past?(&1, conn.assigns.date_time))

    conn
    |> put_view(SiteWeb.ProjectView)
    |> render("show.html", %{
      breadcrumbs: breadcrumbs,
      project: project,
      updates: updates,
      past_events: past_events,
      upcoming_events: upcoming_events
    })
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

  @spec show_project_update(Conn.t(), Content.ProjectUpdate.t()) :: Conn.t()
  def show_project_update(%Conn{} = conn, %Content.ProjectUpdate{} = update) do
    case Repo.get_page(update.project_url) do
      %Content.Project{} = project ->
        breadcrumbs = [
          Breadcrumb.build(@breadcrumb_base, project_path(conn, :index, [])),
          Breadcrumb.build(project.title, project_path(conn, :show, project)),
          Breadcrumb.build(update.title)
        ]

        conn
        |> put_view(SiteWeb.ProjectView)
        |> render("update.html", %{
          breadcrumbs: breadcrumbs,
          update: update
        })

      {:error, {:redirect, _, [to: path]}} ->
        show_project_update(conn, %{update | project_url: path})

      _ ->
        render_404(conn)
    end
  end

  @spec get_events_async(integer) :: (() -> [Content.Event.t()])
  def get_events_async(id), do: fn -> Repo.events(project_id: id) end

  @spec get_updates_async(integer) :: (() -> [Content.Teaser.t()])
  def get_updates_async(id) do
    fn -> Repo.teasers(related_to: id, type: "project_update") end
  end
end
