defmodule Site.StopController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
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

  defp grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.group_by(&Routes.Route.type_atom/1)
    |> Enum.sort_by(&sorter/1)
  end

  defp sorter({:commuter, _}), do: 0
  defp sorter({:subway, _}), do: 1
  defp sorter({:bus, _}), do: 2
  defp sorter({:ferry, _}), do: 3
end
