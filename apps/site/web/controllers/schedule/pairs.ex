defmodule Site.ScheduleController.Pairs do
  use Site.Web, :controller

  import Site.ScheduleController.Helpers

  def pairs(conn, origin_id, dest_id) do
    stop_pairs = Schedules.Repo.origin_destination(
      origin_id, dest_id,
      date: conn.assigns[:date])

    {filtered_pairs, conn} = stop_pairs
    |> filter_pairs(conn.assigns[:show_all])
    |> possibly_open_schedules(stop_pairs, conn)

    conn
    |> assign_direction_id(filtered_pairs)
    |> assign_route_breadcrumbs
    |> await_assign_all
    |> assign_datetime
    |> assign(:schedules, filtered_pairs)
    |> render_pairs(filtered_pairs)
  end

  defp filter_pairs(stop_pairs, show_all)
  defp filter_pairs(stop_pairs, true) do
    stop_pairs
  end
  defp filter_pairs(stop_pairs, false) do
    stop_pairs
    |> Enum.drop_while(fn {_, dest} -> not is_after_now?(dest) end)
  end

  defp assign_direction_id(conn, []), do: conn
  defp assign_direction_id(%{assigns: %{direction_id: direction_id}} = conn,
    [{%{trip: %{direction_id: direction_id}}, _}|_]) do
    # current direction ID matches the default, so nothing to do
    conn
  end
  defp assign_direction_id(%{assigns: %{direction_id: _other_direction_id}} = conn,
    [{%{trip: %{direction_id: direction_id}}, _}|_]) do
    conn
    |> assign(:direction_id, direction_id)
    |> Site.ScheduleController.AllStops.call([]) # need to re-fetch the stops as well
    |> Site.ScheduleController.DestinationStops.call([]) # need to re-fetch the stops as well
  end

  defp render_pairs(conn, []) do
    conn
    |> render("empty.html")
  end
  defp render_pairs(conn, [_ | _]) do
    conn
    |> render("pairs.html")
  end
end
