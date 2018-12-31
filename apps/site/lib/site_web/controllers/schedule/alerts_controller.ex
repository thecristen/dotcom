defmodule SiteWeb.ScheduleController.AlertsController do
  use SiteWeb, :controller
  alias Routes.Route
  alias SiteWeb.ScheduleView

  plug(SiteWeb.Plugs.Route)
  plug(SiteWeb.ScheduleController.Defaults)
  plug(:alerts)
  plug(SiteWeb.Plugs.AlertsByTimeframe)
  plug(SiteWeb.ScheduleController.RouteBreadcrumbs)
  plug(:tab_name)

  def show(conn, _) do
    conn
    |> assign(:meta_description, route_description(conn.assigns.route))
    |> render(ScheduleView, "show.html", [])
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "alerts")

  defp alerts(conn, _), do: assign_alerts(conn, filter_by_direction?: false)

  def route_description(route) do
    "Alerts for MBTA #{do_route_description(Route.type_atom(route), route)}"
  end

  defp do_route_description(:bus, %{id: route_number} = route) do
    "#{bus_type(route)} route #{route_number}"
  end

  defp do_route_description(:subway, route) do
    "#{route.name} #{route_type(route)}"
  end

  defp do_route_description(_, route) do
    ScheduleView.route_header_text(route)
  end

  defp bus_type(route),
    do: if(Route.silver_line_rapid_transit?(route), do: "Silver Line", else: "bus")

  defp route_type(route) do
    route
    |> Route.type_atom()
    |> Route.type_name()
  end
end
