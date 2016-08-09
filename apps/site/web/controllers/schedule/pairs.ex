defmodule Site.ScheduleController.Pairs do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers

  def pairs(conn, route_id, origin_id, dest_id) do
    conn = conn
    |> default_assigns
    |> assign_route(route_id)
    |> assign_alerts
    |> assign_all_stops(route_id)

    opts = [
      direction_id: conn.assigns[:direction_id],
      date: conn.assigns[:date]
    ]

    stop_pairs = Schedules.Repo.origin_destination(origin_id, dest_id, opts)

    {filtered_pairs, conn} = stop_pairs
    |> filter_pairs(conn.assigns[:show_all])
    |> possibly_open_schedules(stop_pairs, conn)

    conn
    |> assign_all_routes
    |> assign_route_breadcrumbs
    |> await_assign_all
    |> route_alerts
    |> stop_alerts
    |> trip_alerts
    |> render_pairs(filtered_pairs)
  end

  defp filter_pairs(stop_pairs, show_all)
  defp filter_pairs(stop_pairs, true) do
    stop_pairs
  end
  defp filter_pairs(stop_pairs, false) do
    stop_pairs
    |> Enum.filter(fn {_, dest} -> is_after_now?(dest) end)
  end

  defp render_pairs(conn, []) do
    conn
    |> render("empty.html")
  end
  defp render_pairs(conn, pairs) do
    conn
    |> render("pairs.html",
    to: pairs |> Enum.map(&(elem(&1, 1))) |> to,
    pairs: pairs
    )
  end
end
