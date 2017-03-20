defmodule Site.EventController do
  use Site.Web, :controller
  alias Site.EventQueryBuilder

  def index(conn, %{"start_time_gt" => _, "start_time_lt" => _} = params) do
    events = Content.Repo.all("events", params)

    conn
    |> render("index.html", events: events)
  end
  def index(conn, _params) do
    events = Content.Repo.all("events", params_for_upcoming_events())

    conn
    |> render("index.html", events: events)
  end

  def show(conn, %{"id" => id}) do
    event = Content.Repo.get!("events", id)

    conn
    |> assign_breadcrumbs(event)
    |> render("show.html", event: event)
  end

  defp params_for_upcoming_events do
    EventQueryBuilder.upcoming_events(Timex.today)
  end

  defp assign_breadcrumbs(conn, event) do
    conn
    |> assign(:breadcrumbs, [
        {event_path(conn, :index), "Events"},
        event.title
      ])
  end
end
