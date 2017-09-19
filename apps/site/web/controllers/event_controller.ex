defmodule Site.EventController do
  use Site.Web, :controller
  alias Site.EventDateRange
  alias Plug.Conn

  def index(conn, params) do
    date_range = EventDateRange.build(params, Util.today)
    events = Content.Repo.events(Enum.into(date_range, []))

    conn
    |> assign(:month, date_range.start_time_gt)
    |> assign(:events, events)
    |> assign(:breadcrumbs, [Breadcrumb.build("Events")])
    |> assign(:narrow_template, true)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    case Content.Repo.event(id) do
      :not_found -> check_cms_or_404(conn)
      event ->
        conn
        |> assign(:narrow_template, true)
        |> assign_breadcrumbs(event)
        |> render("show.html", event: event)
    end
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
