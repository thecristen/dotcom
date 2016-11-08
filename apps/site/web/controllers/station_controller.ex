defmodule Site.StationController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.Alerts

  alias Stations.Repo

  def index(conn, _params) do
    stations = Repo.all
    render(conn, "index.html", stations: stations, breadcrumbs: ["Stations"])
  end

  def show(conn, params) do
    id = params["id"]
    station = Repo.get!(id |> String.replace("+", " "))
    conn
    |> assign(:map_url, Stations.Maps.by_name(station.name))
    |> assign(:grouped_routes, grouped_routes(id))
    |> assign(:breadcrumbs, [{station_path(conn, :index), "Stations"}, station.name])
    |> assign(:tab, params["tab"])
    |> render("show.html", station: station)
  end

  def grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Routes.Group.group
  end
end
