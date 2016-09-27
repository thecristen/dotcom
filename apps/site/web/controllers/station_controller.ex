defmodule Site.StationController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.Alerts

  alias Stations.Repo

  def index(conn, _params) do
    stations = Repo.all
    render(conn, "index.html", stations: stations)
  end

  def show(conn, %{"id" => id}) do
    station = Repo.get!(id |> String.replace("+", " "))
    conn
    |> assign(:map_url, Stations.Maps.by_name(station.name))
    |> assign(:grouped_routes, grouped_routes(id))
    |> render("show.html", station: station)
  end

  def grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.map(&map_0_type/1)
    |> Enum.group_by(&(&1.type))
  end

  defp map_0_type(%{type: 0} = route) do
    %{route|type: 1}
  end
  defp map_0_type(route), do: route
end
