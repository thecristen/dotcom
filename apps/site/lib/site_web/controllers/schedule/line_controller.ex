defmodule SiteWeb.ScheduleController.LineController do
  use SiteWeb, :controller
  alias Phoenix.HTML
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
  plug(:channel_id)

  def show(conn, _) do
    conn =
      conn
      |> assign(:meta_description, route_description(conn.assigns.route))
      |> assign(:disable_turbolinks, true)
      |> put_view(ScheduleView)
      |> await_assign_all_default(__MODULE__)

    conn
    |> assign(
      :schedule_page_data,
      %{
        pdfs:
          ScheduleView.route_pdfs(conn.assigns.route_pdfs, conn.assigns.route, conn.assigns.date),
        teasers:
          HTML.safe_to_string(
            ScheduleView.render(
              "_cms_teasers.html",
              conn.assigns
            )
          ),
        hours: HTML.safe_to_string(ScheduleView.render("_hours_of_op.html", conn.assigns)),
        fares:
          Enum.map(ScheduleView.single_trip_fares(conn.assigns.route), fn {title, price} ->
            %{title: title, price: price}
          end),
        fare_link: ScheduleView.route_fare_link(conn.assigns.route),
        holidays: conn.assigns.holidays
      }
    )
    |> render("show.html", [])
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "line")

  defp alerts(conn, _), do: assign_alerts(conn, [])

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
    do: if(Route.silver_line?(route), do: "Silver Line", else: "bus")

  defp route_type(route) do
    route
    |> Route.type_atom()
    |> Route.type_name()
  end
end
