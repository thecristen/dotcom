defmodule Site.ScheduleController.Route do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers
  import Site.ScheduleController.Query

  def route(conn, route_id) do
    conn
    |> default_assigns
    |> assign_route(route_id)
    |> assign_alerts
    |> assign_selected_trip
    |> assign_all_stops(route_id)
    |> assign_destination_stops(route_id)
    |> render_route
  end

  defp render_route(%{assigns: %{route: nil}} = conn) do
    # no route found
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
  end
  defp render_route(conn) do
    conn
    |> schedule_query
    |> Schedules.Repo.all
    |> render_schedules(conn)
  end

  defp render_schedules([], conn) do
    conn
    |> assign(:schedules, [])
    |> assign_all_routes
    |> await_assign_all
    |> assign_datetime
    |> route_alerts
    |> stop_alerts
    |> render("empty.html")
  end
  defp render_schedules(all_schedules, conn) do
    {filtered_schedules, conn} = all_schedules
    |> upcoming_schedules(conn.assigns[:show_all])
    |> possibly_open_schedules(all_schedules, conn)

    conn
    |> assign_all_routes
    |> assign(:schedules, filtered_schedules)
    |> assign(:from, from(all_schedules, conn))
    |> assign(:to, to(all_schedules))
    |> assign(:most_frequent_headsign, most_frequent_headsign(filtered_schedules))
    |> assign_list_group_template
    |> assign_route_breadcrumbs
    |> await_assign_all
    |> assign_datetime
    |> route_alerts
    |> stop_alerts
    |> trip_alerts
    |> render("index.html")
  end

  defp upcoming_schedules(all_schedules, show_all)
  defp upcoming_schedules(all_schedules, true) do
    all_schedules
    |> sort_schedules
  end
  defp upcoming_schedules(all_schedules, false) do
    default_schedules = upcoming_schedules(all_schedules, true)

    first_after_index = default_schedules
    |> Enum.find_index(&is_after_now?/1)

    if first_after_index == nil do
      []
    else
      all_schedules
      |> Enum.drop(first_after_index - 1)
    end
  end

  defp sort_schedules(all_schedules) do
    all_schedules
    |> Enum.sort_by(fn schedule -> schedule.time end)
  end

  defp most_frequent_headsign(schedules) do
    schedules
    |> Enum.map(&(&1.trip.headsign))
    |> most_frequent_value
  end

  defp assign_list_group_template(%{assigns: %{route: %{type: type}}} = conn) do
    list_group_template = case type do
                            0 ->
                              "subway.html"
                            1 ->
                              "subway.html"
                            3 ->
                              "bus.html"
                            _ ->
                              "rail.html"
                          end

    conn
    |> assign(:list_group_template, list_group_template)
  end
end
