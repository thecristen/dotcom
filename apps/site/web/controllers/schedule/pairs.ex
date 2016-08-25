defmodule Site.ScheduleController.Pairs do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers

  def pairs(conn, route_id, origin_id, dest_id) do
    conn = conn
    |> default_assigns

    opts = [
      date: conn.assigns[:date]
    ]

    stop_pairs = Schedules.Repo.origin_destination(origin_id, dest_id, opts)

    {filtered_pairs, conn} = stop_pairs
    |> filter_pairs(conn.assigns[:show_all])
    |> possibly_open_schedules(stop_pairs, conn)

    conn
    |> assign_direction_id(filtered_pairs)
    |> assign_route(route_id)
    |> assign_all_stops(route_id)
    |> assign_destination_stops(route_id)
    |> assign_alerts
    |> assign_all_routes
    |> assign_route_breadcrumbs
    |> await_assign_all
    |> assign_datetime
    |> route_alerts
    |> stop_alerts
    |> trip_alerts
    |> assign(:schedules, filtered_pairs)
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

  defp assign_direction_id(conn, []), do: conn
  defp assign_direction_id(conn, [{%{trip: %{direction_id: direction_id}}, _}|_]) do
    conn
    |> assign(:direction_id, direction_id)
    |> assign(:reverse_direction_id, reverse_direction_id(direction_id))
  end

  defp render_pairs(conn, []) do
    conn
    |> render("empty.html")
  end
  defp render_pairs(conn, pairs) do
    conn
    |> render("pairs.html",
    to: pairs |> Enum.map(&(elem(&1, 1))) |> to,
    )
  end
end
