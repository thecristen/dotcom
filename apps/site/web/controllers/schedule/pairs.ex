defmodule Site.ScheduleController.Pairs do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers

  def pairs(conn, origin_id, dest_id) do
    conn = conn
    |> default_assigns
    |> assign_alerts

    opts = []
    |> Dict.put(:direction_id, conn.assigns[:direction_id])
    |> Dict.put(:date, conn.assigns[:date])

    stop_pairs = Schedules.Repo.origin_destination(origin_id, dest_id, opts)

    {filtered_pairs, conn} = filter_pairs(stop_pairs, conn)

    conn
    |> assign(:route, general_route(stop_pairs))
    |> assign_all_routes
    |> await_assign_all
    |> route_alerts
    |> render("pairs.html",
      to: stop_pairs |> Enum.map(&(elem(&1, 1))) |> to,
      pairs: filtered_pairs
    )
  end

  defp general_route(stop_pairs) do
    stop_pairs
    |> Enum.map(fn {stop, _} -> stop.route end)
    |> most_frequent_value
  end

  defp filter_pairs(stop_pairs, conn) do
    stop_pairs
    |> Enum.filter(fn {_, dest} -> is_after_now?(dest) end)
    |> possibly_open_schedules(stop_pairs, conn)
  end
end
