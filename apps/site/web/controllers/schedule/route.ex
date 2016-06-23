defmodule Site.ScheduleController.Route do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers
  import Site.ScheduleController.Query

  def route(conn, route_id) do
    conn = conn
    |> default_assigns
    |> assign_route(route_id)
    |> assign_alerts
    |> assign_selected_trip
    |> assign_all_stops(route_id)

    all_schedules = conn
    |> schedule_query
    |> Schedules.Repo.all

    {filtered_schedules, conn} = all_schedules
    |> schedules(conn.assigns[:show_all])
    |> possibly_open_schedules(all_schedules, conn)

    conn
    |> assign_all_routes
    |> assign(:schedules, filtered_schedules)
    |> assign(:from, from(all_schedules))
    |> assign(:to, to(all_schedules))
    |> assign_list_group_template
    |> await_assign_all
    |> render("index.html")
  end

  defp schedules(all_schedules, show_all)
  defp schedules(all_schedules, true) do
    all_schedules
    |> sort_schedules
  end
  defp schedules(all_schedules, false) do
    default_schedules = schedules(all_schedules, true)

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

  defp from(all_schedules) do
    # Given a list of schedules, return where those schedules start (best-guess)
    all_schedules
    |> Enum.map(fn schedule -> schedule.stop.name end)
    |> most_frequent_value
  end

  defp to(all_schedules) do
    # Given a list of schedules, return where those schedules stop (best-guess)
    all_schedules
    |> Enum.map(fn schedule -> schedule.trip.headsign end)
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
