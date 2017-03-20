defmodule Site.EventController do
  use Site.Web, :controller
  alias Site.EventDateRange

  def index(conn, params) do
    date_range = EventDateRange.build(params, Util.today)
    events = Content.Repo.all("events", date_range)

    conn
    |> assign(:month, date_range.start_time_gt)
    |> assign(:events, events)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    event = Content.Repo.get!("events", id)

    conn
    |> assign_breadcrumbs(event)
    |> render("show.html", event: event)
  end

  defp assign_breadcrumbs(conn, event) do
    conn
    |> assign(:breadcrumbs, [
        {event_path(conn, :index), "Events"},
        event.title
      ])
  end
end
