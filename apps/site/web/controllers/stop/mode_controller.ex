defmodule Site.StopController.ModeController do
  use Site.Web, :controller

  def show(conn, mode) do
    stop_info = mode
    |> types_for_mode
    |> Routes.Repo.by_type
    |> Enum.map(&{&1, Schedules.Repo.stops(&1.id, [])})
    |> gather_green_line(mode)

    render(conn, "index.html", mode: mode, stop_info: stop_info, breadcrumbs: ["Stops"])
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
  defp gather_green_line(stop_info, _mode), do: stop_info

  @spec types_for_mode(Route.gtfs_route_type) :: [0..4]
  defp types_for_mode(:subway), do: [0, 1]
  defp types_for_mode(:commuter_rail), do: [2]
  defp types_for_mode(:bus), do: [3]
  defp types_for_mode(:ferry), do: [4]
end
