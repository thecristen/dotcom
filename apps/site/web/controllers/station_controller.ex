defmodule Site.StationController do
  use Site.Web, :controller

  alias Stations.Station
  alias Stations.Repo

  def index(conn, _params) do
    stations = Repo.all
    render(conn, "index.html", stations: stations)
  end

  def show(conn, %{"id" => id}) do
    station = Repo.get!(Station, id |> String.replace("+", " "))
    render(conn, "show.html", station: station)
  end
end
