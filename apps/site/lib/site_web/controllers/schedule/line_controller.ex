defmodule SiteWeb.ScheduleController.LineController do
  use SiteWeb, :controller
  alias Routes.Route
  alias SiteWeb.ScheduleView

  plug(SiteWeb.Plugs.Route)
  plug(SiteWeb.Plugs.DateInRating)
  plug(:tab_name)
  plug(SiteWeb.ScheduleController.RoutePdfs)
  plug(SiteWeb.ScheduleController.Defaults)
  plug(:alerts)
  plug(SiteWeb.ScheduleController.AllStops)
  plug(SiteWeb.ScheduleController.RouteBreadcrumbs)
  plug(SiteWeb.ScheduleController.HoursOfOperation)
  plug(SiteWeb.ScheduleController.Holidays)
  plug(SiteWeb.ScheduleController.VehicleLocations)
  plug(SiteWeb.ScheduleController.Predictions)
  plug(SiteWeb.ScheduleController.VehicleTooltips)
  plug(SiteWeb.ScheduleController.Line)
  plug(SiteWeb.ScheduleController.CMS)
  plug(:require_map)
  plug(:channel_id)

  def show(conn, _) do
    conn
    |> assign(:meta_description, route_description(conn.assigns.route))
    |> render(ScheduleView, "show.html", [])
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "line")

  defp alerts(conn, _), do: assign_alerts(conn, [])

  defp require_map(conn, _), do: assign(conn, :requires_google_maps?, true)

  defp channel_id(conn, _) do
    assign(conn, :channel, "vehicles:#{conn.assigns.route.id}:#{conn.assigns.direction_id}")
  end

  defp route_description(route) do
    case Route.type_atom(route) do
      :bus ->
        bus_description(route)

      :subway ->
        line_description(route)

      _ ->
        "MBTA #{ScheduleView.route_header_text(route)} stops and schedules, including maps, " <>
          "parking and accessibility information, and fares."
    end
  end

  defp bus_description(%{id: route_number} = route) do
    "MBTA #{bus_type(route)} route #{route_number} stops and schedules, including maps, real-time updates, " <>
      "parking and accessibility information, and connections."
  end

  defp line_description(route) do
    "MBTA #{route.name} #{route_type(route)} stations and schedules, including maps, real-time updates, " <>
      "parking and accessibility information, and connections."
  end

  defp bus_type(route),
    do: if(Route.silver_line_rapid_transit?(route), do: "Silver Line", else: "bus")

  defp route_type(route) do
    route
    |> Route.type_atom()
    |> Route.type_name()
  end
end
