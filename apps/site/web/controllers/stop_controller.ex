defmodule Site.StopController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.Alerts

  alias Stops.Repo

  def index(conn, _params) do
    stops = Repo.all
    render(conn, "index.html", stops: stops, breadcrumbs: ["Stops"])
  end

  def show(conn, %{"id" => id}) do
    stop = Repo.get!(id |> String.replace("+", " "))
    conn
    |> assign(:map_url, Stops.Maps.by_name(stop.name))
    |> assign(:grouped_routes, grouped_routes(id))
    |> assign(:breadcrumbs, [{stop_path(conn, :index), "Stops"}, stop.name])
    |> render("show.html", stop: stop)
  end

  def grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Routes.Group.group
  end
end
