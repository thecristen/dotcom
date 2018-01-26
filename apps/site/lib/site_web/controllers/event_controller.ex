defmodule SiteWeb.EventController do
  use SiteWeb, :controller
  alias SiteWeb.EventDateRange
  alias Plug.Conn

  def index(conn, params) do
    {:ok, current_month} = Date.new(Util.today.year, Util.today.month, 1)
    date_range = EventDateRange.build(params, current_month)
    events = Content.Repo.events(Enum.into(date_range, []))

    conn
    |> assign(:month, date_range.start_time_gt)
    |> assign(:events, events)
    |> assign(:breadcrumbs, [Breadcrumb.build("Events")])
    |> assign(:narrow_template, true)
    |> render("index.html", conn: conn)
  end

  def show(conn, params) do
    params
    |> best_cms_path(conn.request_path)
    |> Content.Repo.get_page(conn.query_params)
    |> do_show(conn)
  end

  defp do_show(%Content.Event{} = event, conn), do: show_event(conn, event)
  defp do_show({:error, {:redirect, path}}, conn), do: redirect conn, to: path
  defp do_show(_404_or_mismatch, conn), do: render_404(conn)

  @spec show_event(Plug.Conn.t, Content.Event.t) :: Plug.Conn.t
  def show_event(conn, event) do
    conn
    |> assign(:narrow_template, true)
    |> assign_breadcrumbs(event)
    |> render("show.html", event: event)
  end

  @spec assign_breadcrumbs(Conn.t, Content.Event.t) :: Conn.t
  defp assign_breadcrumbs(conn, event) do
    conn
    |> assign(:breadcrumbs, [
        Breadcrumb.build("Events", event_path(conn, :index)),
        Breadcrumb.build(event.title)
      ])
  end
end
