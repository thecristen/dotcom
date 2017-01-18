defmodule Site.ScheduleController.Green do
  use Site.Web, :controller

  @routes ["B", "C", "D", "E"]
  |> Enum.map(&(%Routes.Route{id: "Green-" <> &1, name: &1}))

  alias Site.ScheduleController

  plug :route
  plug :green_routes
  plug Site.Plugs.Date
  plug ScheduleController.Defaults
  plug :green_schedules
  plug ScheduleController.DateTime
  plug ScheduleController.RouteBreadcrumbs
  plug ScheduleController.DatePicker
  plug :headsigns

  def green(conn, _params) do
    conn
    |> render(Site.ScheduleView, "green.html", [])
  end

  def route(conn, []) do
    conn
    |> assign(:route, %Routes.Route{id: "Green", name: "Green Line", type: 0})
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

  defp schedule_for_route(
    %{id: route_id} = route,
    %{assigns: %{direction_id: direction_id}} = conn) do
    stops = Schedules.Repo.stops(
      route_id,
      direction_id: direction_id)

    # update the route in the conn for this request
    conn = %{conn|params:
             conn.params
             |> Map.put("route", route_id)}
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
