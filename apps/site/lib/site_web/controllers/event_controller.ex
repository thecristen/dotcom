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

  def show(conn, %{"alias" => [id]}) do
    event = id
    |> Content.Helpers.int_or_string_to_int()
    |> Content.Repo.event()
    do_show(conn, event)
  end
  def show(conn, _), do: do_show(conn, Content.Repo.get_page(conn.request_path, conn.query_params))

  def do_show(conn, maybe_event) do
    case maybe_event do
      :not_found -> check_cms_or_404(conn)
      event -> show_event(conn, event)
    end
  end

  @spec show_event(Conn.t, Content.Event.t) :: Conn.t
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
