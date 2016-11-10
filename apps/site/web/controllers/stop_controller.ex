defmodule Site.StopController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.Alerts

  alias Stops.Repo

  def index(conn, _params) do
    stops = Repo.stations
    render(conn, "index.html", stops: stops, breadcrumbs: ["Stops"])
  end

  def show(conn, params) do
    id = params["id"]
    stop = Repo.get!(id |> String.replace("+", " "))
    conn
    |> assign(:grouped_routes, grouped_routes(id))
    |> assign(:breadcrumbs, [{stop_path(conn, :index), "Stops"}, stop.name])
    |> assign(:tab, params["tab"])
    |> assign(:zone_name, Fares.calculate("1A", Zones.Repo.get(stop.id)))
    |> render("show.html", stop: stop)
  end

  def grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Routes.Group.group
  end
end
