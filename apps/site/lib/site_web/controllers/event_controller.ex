defmodule SiteWeb.EventController do
  use SiteWeb, :controller
  alias SiteWeb.EventDateRange
  alias Site.IcalendarGenerator
  alias Plug.Conn

  def index(conn, params) do
    {:ok, current_month} = Date.new(Util.today.year, Util.today.month, 1)
    date_range = EventDateRange.build(params, current_month)
    events = Content.Repo.events(Enum.into(date_range, []))

    conn
    |> assign(:month, date_range.start_time_gt)
    |> assign(:events, events)
    |> assign(:breadcrumbs, [Breadcrumb.build("Events")])
    |> render("index.html", conn: conn)
  end

  def show(conn, %{"path_params" => path}) do
    case List.last(path) do
      "icalendar" ->
        redirect conn, to: Path.join(["/events", "icalendar" | Enum.slice(path, 0..-2)])
      _ ->
        conn.request_path
        |> Content.Repo.get_page(conn.query_params)
        |> do_show(conn)
    end
  end

  defp do_show(%Content.Event{} = event, conn) do
    show_event(conn, event)
  end
  defp do_show({:error, {:redirect, status, opts}}, conn) do
    conn
    |> put_status(status)
    |> redirect(opts)
  end
  defp do_show(_404_or_mismatch, conn) do
    render_404(conn)
  end

  @spec show_event(Plug.Conn.t, Content.Event.t) :: Plug.Conn.t
  def show_event(conn, event) do
    conn
    |> assign_breadcrumbs(event)
    |> render(SiteWeb.EventView, "show.html", event: event)
  end

  @spec assign_breadcrumbs(Conn.t, Content.Event.t) :: Conn.t
  defp assign_breadcrumbs(conn, event) do
    conn
    |> assign(:breadcrumbs, [
        Breadcrumb.build("Events", event_path(conn, :index)),
        Breadcrumb.build(event.title)
      ])
  end

  @spec icalendar(Plug.Conn.t, map) :: Plug.Conn.t
  def icalendar(%{request_path: path} = conn, _) do
    path
    |> String.replace("/icalendar", "")
    |> Content.Repo.get_page(conn.query_params)
    |> do_icalendar(conn)
  end

  @spec do_icalendar(Content.Page.t | {:error, Content.CMS.error}, Plug.Conn.t) :: Plug.Conn.t
  defp do_icalendar(%Content.Event{} = event, conn) do
    conn
    |> put_resp_content_type("text/calendar")
    |> put_resp_header("content-disposition", "attachment; filename='#{filename(event.title)}.ics'")
    |> send_resp(200, IcalendarGenerator.to_ical(conn, event))
  end
  defp do_icalendar({:error, {:redirect, _status, [to: path]}}, conn) do
    path
    |> Content.Repo.get_page(conn.query_params)
    |> do_icalendar(conn)
  end
  defp do_icalendar(_, conn) do
    render_404(conn)
  end

  @spec filename(String.t) :: String.t
  defp filename(title) do
    title
    |> String.downcase
    |> String.replace(" ", "_")
    |> decode_ampersand_html_entity
  end

  @spec decode_ampersand_html_entity(String.t) :: String.t
  defp decode_ampersand_html_entity(string) do
    String.replace(string, "&amp;", "&")
  end
end
