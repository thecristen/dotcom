defmodule SiteWeb.StopController do
  @moduledoc """
  Page for display of information about in individual stop or station.
  """
  use SiteWeb, :controller
  alias Plug.Conn
  alias Routes.{Group, Route}
  alias SiteWeb.PartialView.HeaderTab
  alias SiteWeb.StopController.StopMap
  alias SiteWeb.StopView.Parking
  alias SiteWeb.Views.Helpers.AlertHelpers
  alias Stops.{Repo, Stop}
  alias Util.AndOr

  plug(:alerts)

  @type routes_map_t :: %{
          group_name: atom,
          routes: [Route.t()]
        }

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"stop" => stop}) do
    if Laboratory.enabled?(conn, :stop_page_redesign) do
      stop =
        stop
        |> URI.decode_www_form()
        |> Repo.get()

      if stop do
        routes_by_stop = Routes.Repo.by_stop(stop.id)
        grouped_routes = grouped_routes(routes_by_stop)
        routes_map = routes_map(grouped_routes)
        json_safe_routes = json_safe_routes(routes_map)

        conn
        |> assign(:stop, stop)
        |> assign(:routes, json_safe_routes)
        |> assign(:requires_google_maps?, true)
        |> assign(:map_data, StopMap.map_info(stop, routes_map))
        |> assign(:zone_number, Zones.Repo.get(stop.id))
        |> assign_stop_page_data()
        |> meta_description(stop, routes_by_stop)
        |> render("show.html")
      else
        check_cms_or_404(conn)
      end
    else
      render_404(conn)
    end
  end

  @spec grouped_routes([Route.t()]) :: [{Route.gtfs_route_type(), [Route.t()]}]
  defp grouped_routes(routes) do
    routes
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&Group.sorter/1)
  end

  @spec routes_map([{Route.gtfs_route_type(), [Route.t()]}]) :: [routes_map_t]
  def routes_map(grouped_routes) do
    grouped_routes
    |> Enum.map(fn {group, routes} -> %{group_name: group, routes: routes} end)
  end

  defp alerts(%{path_params: %{"stop" => stop}} = conn, _opts) do
    stop_id = URI.decode_www_form(stop)

    alerts =
      conn.assigns.date_time
      |> Alerts.Repo.all()
      |> Alerts.Stop.match(stop_id)

    conn
    |> assign(:alerts, alerts)
    |> assign(:all_alerts_count, length(alerts))
  end

  defp json_safe_routes(routes_map) do
    routes_map
    |> Enum.map(fn group_and_routes ->
      safe_routes = group_and_routes.routes |> Enum.map(&Route.to_json_safe(&1))

      %{
        group_name: group_and_routes.group_name,
        routes: safe_routes
      }
    end)
  end

  defp assign_stop_page_data(
         %{
           assigns: %{
             stop: stop,
             routes: routes,
             all_alerts_count: all_alerts_count,
             zone_number: zone_number
           }
         } = conn
       ) do
    assign(conn, :stop_page_data, %{
      stop: %{stop | parking_lots: Enum.map(stop.parking_lots, &Parking.parking_lot(&1))},
      routes: routes,
      tabs: [
        %HeaderTab{
          id: "details",
          name: "Station Details",
          href: stop_path(conn, :show, stop.id)
        },
        %HeaderTab{
          id: "alerts",
          name: "Alerts",
          class: "header-tab--alert",
          href: stop_v1_path(conn, :show, stop.id, tab: "alerts"),
          badge: AlertHelpers.alert_badge(all_alerts_count)
        }
      ],
      zone_number: zone_number
    })
  end

  @spec meta_description(Conn.t(), Stop.t(), [Route.t()]) :: Conn.t()
  defp meta_description(conn, stop, routes),
    do:
      assign(
        conn,
        :meta_description,
        "Station serving MBTA #{lines(routes)} lines#{location(stop)}."
      )

  @spec lines([Route.t()]) :: iolist
  defp lines(routes) do
    routes
    |> Enum.map(&(&1.type |> Route.type_atom() |> Route.type_name()))
    |> Enum.uniq()
    |> AndOr.join(:and)
  end

  @spec location(Stop.t()) :: String.t()
  defp location(stop) do
    if stop.address && stop.address != "" do
      " at #{stop.address}"
    else
      ""
    end
  end
end
