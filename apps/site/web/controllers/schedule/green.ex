defmodule Site.ScheduleController.Green do
  use Site.Web, :controller

  @routes ["B", "C", "D", "E"]
  |> Enum.map(&(%Routes.Route{id: "Green-" <> &1, name: &1}))

  alias Site.ScheduleController

  plug :route
  plug :green_routes
  plug ScheduleController.Defaults
  plug :green_schedules
  plug ScheduleController.AllRoutes
  plug ScheduleController.DateTime
  plug ScheduleController.RouteBreadcrumbs
  plug :assign_additional_route_to_all_routes
  plug :headsigns

  def green(conn, _) do
    render conn, Site.ScheduleView, "green.html", []
  end

  def route(conn, []) do
    conn
    |> assign(:route, %Routes.Route{id: "Green", name: "Green", type: 0})
  end

  def green_routes(conn, []) do
    conn
    |> assign(:green_routes, @routes)
  end

  def green_schedules(conn, []) do
    schedules = @routes
    |> Enum.map(fn route -> schedule_for_route(route, conn) end)

    conn
    |> assign(:green_schedules, schedules)
  end

  @doc "Includes the fake Green line route in the list of all routes"
  def assign_additional_route_to_all_routes(
    %{assigns: %{route: route, all_routes: all_routes}} = conn, []) do
    conn
    |> assign(:all_routes, [route|all_routes])
  end

  defp schedule_for_route(
    %{id: route_id} = route,
    %{assigns: %{direction_id: direction_id}} = conn) do
    stops = Schedules.Repo.stops(
      route_id,
      direction_id: direction_id)

    # update the route in the conn for this request
    conn = %{conn|params:
             conn.params
             |> Dict.put("route", route_id)}
             |> assign(:all_stops, stops)
             |> ScheduleController.Schedules.call([])
             |> ScheduleController.DirectionNames.call([])

    {route, conn.assigns.all_schedules, conn.assigns.from}
  end

  def headsigns(conn, []) do
    conn
    |> assign(:headsigns, %{
          0 => [],
          1 => []
              })
  end
end
