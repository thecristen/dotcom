defmodule Site.StopController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.Plugs.Alerts

  alias Stops.Repo

  def index(conn, _params) do
    redirect conn, to: stop_path(conn, :show, :subway)
  end

  def show(conn, %{"id" => mode}) when mode in ["subway", "commuter_rail", "ferry"] do
    render_mode(conn, String.to_existing_atom(mode))
  end
  def show(conn, params) do
    id = params["id"]
    stop = Repo.get!(id |> String.replace("+", " "))
    conn
    |> assign(:grouped_routes, grouped_routes(id))
    |> assign(:breadcrumbs, breadcrumbs(stop))
    |> assign(:tab, params["tab"])
    |> assign(:zone_name, Fares.calculate("1A", Zones.Repo.get(stop.id)))
    |> render("show.html", stop: stop)
  end

  @spec render_mode(Plug.Conn.t, Routes.Route.gtfs_route_type) :: Plug.Conn.t
  defp render_mode(conn, mode) do
    stop_info = mode
    |> types_for_mode
    |> Routes.Repo.by_type
    |> Enum.map(&{&1, Schedules.Repo.stops(&1.id, [])})
    |> gather_green_line(mode)
    |> Enum.into(%{})

    render(conn, "index.html", mode: mode, stop_info: stop_info, breadcrumbs: ["Stops"])
  end

  @spec gather_green_line([{Routes.Route.t, [Stops.Stop.t]}], Routes.Route.gtfs_route_type) :: [{Routes.Route.t, [Stops.Stop.t]}]
  defp gather_green_line(stop_info, :subway) do
    {green_branches, others} = stop_info
    |> Enum.partition(&String.starts_with?(elem(&1, 0).id, "Green-"))

    green_stops = green_branches
    |> Enum.flat_map(&elem(&1, 1))
    |> Enum.uniq

    [{%{name: "Green"}, green_stops} | others]
  end
  defp gather_green_line(stop_info, _mode), do: stop_info

  @spec types_for_mode(Routes.Route.gtfs_route_type) :: [0..4]
  defp types_for_mode(:subway), do: [0, 1]
  defp types_for_mode(:commuter_rail), do: [2]
  defp types_for_mode(:ferry), do: [4]

  @spec grouped_routes(String.t) :: [{Routes.Route.gtfs_route_type, Routes.Route.t}]
  defp grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.group_by(&Routes.Route.type_atom/1)
    |> Enum.sort_by(&sorter/1)
  end

  @spec sorter({Routes.Route.gtfs_route_type, Routes.Route.t}) :: non_neg_integer
  defp sorter({:commuter_rail, _}), do: 0
  defp sorter({:subway, _}), do: 1
  defp sorter({:bus, _}), do: 2
  defp sorter({:ferry, _}), do: 3

  @spec breadcrumbs(Stops.Stop.t) :: [{String.t, String.t} | String.t]
  defp breadcrumbs(%Stops.Stop{station?: true, name: name}) do
    [{stop_path(Site.Endpoint, :index), "Stations"}, name]
  end
  defp breadcrumbs(%Stops.Stop{name: name}) do
    [name]
  end
end
