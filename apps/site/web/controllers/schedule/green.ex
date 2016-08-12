defmodule Site.ScheduleController.Green do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers
  import Site.ScheduleController.Query

  def green(conn) do
    # special case for the Green Line summary
    routes = for line <- ["B", "C", "D", "E"] do
      %Routes.Route{id: "Green-" <> line, name: line}
    end

    conn = conn
    |> default_assigns
    |> assign(:route, %Routes.Route{id: "Green", name: "Green", type: 0})
    |> assign(:green_routes, routes)

    conn
    |> async_assign(:green_schedules, fn ->
      routes
      |> Enum.map(fn route ->
        stops = Schedules.Repo.stops(
        route.id,
        direction_id: conn.assigns[:direction_id])

        # update the route in the conn for this request
        conn = %{conn|params:
                 conn.params
                 |> Dict.put("route", route.id)}
        |> assign(:all_stops, stops)


        all_schedules = conn
        |> schedule_query
        |> Schedules.Repo.all

        {route, all_schedules, from(all_schedules, conn)}
      end)
    end)
    |> assign_all_routes
    |> await_assign_all
    |> assign_datetime
    |> assign_additional_route_to_all_routes
    |> render("green.html")
  end

  @doc "Includes the fake Green line route in the list of all routes"
  def assign_additional_route_to_all_routes(
    %{assigns: %{route: route, all_routes: all_routes}} = conn) do
    conn
    |> assign(:all_routes, [route|all_routes])
  end
end
