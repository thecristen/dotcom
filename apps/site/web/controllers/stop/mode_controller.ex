defmodule Site.StopController.ModeController do
  use Site.Web, :controller

  alias Routes.Route
  alias Stops.Stop

  @spec show(Plug.Conn.t, Route.gtfs_route_type) :: Plug.Conn.t
  def show(conn, mode) do
    stop_info = mode
    |> types_for_mode
    |> Routes.Repo.by_type
    |> ParallelStream.map(&{&1, Stops.Repo.by_route(&1.id, 0)})
    |> Enum.into([])
    |> gather_green_line(mode)

    render(conn, "index.html", mode: mode, stop_info: stop_info, breadcrumbs: ["Stations"])
  end

  @spec gather_green_line([{Route.t, [Stop.t]}], Route.gtfs_route_type) :: [{Route.t, [Stop.t]}]
  defp gather_green_line(stop_info, :subway) do
    {green_branches, others} = stop_info
    |> Enum.partition(&String.starts_with?(elem(&1, 0).id, "Green-"))

    green_stops = green_branches
    |> Enum.flat_map(&elem(&1, 1))
    |> Enum.uniq

    [{%{name: "Green"}, green_stops} | others]
  end
  defp gather_green_line(stop_info, _mode), do: Enum.into(stop_info, [])

  @spec types_for_mode(Route.gtfs_route_type) :: [0..4]
  defp types_for_mode(:subway), do: [0, 1]
  defp types_for_mode(:commuter_rail), do: [2]
  defp types_for_mode(:bus), do: [3]
  defp types_for_mode(:ferry), do: [4]
end
