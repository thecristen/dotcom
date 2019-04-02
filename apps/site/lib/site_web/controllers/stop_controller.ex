defmodule SiteWeb.StopController do
  @moduledoc """
  Page for display of information about in individual stop or station.
  """
  use SiteWeb, :controller
  alias Plug.Conn
  alias Fares.{RetailLocations, RetailLocations.Location}
  alias Site.JsonHelpers
  alias Routes.{Group, Route}
  alias Site.TransitNearMe
  alias SiteWeb.PartialView.HeaderTab
  alias SiteWeb.StopController.StopMap
  alias SiteWeb.StopView.Parking
  alias SiteWeb.ViewHelpers
  alias SiteWeb.Views.Helpers.AlertHelpers
  alias Stops.{Nearby, Repo, Stop}
  alias Util.AndOr

  plug(:alerts)

  @distance_tenth_of_a_mile 0.002
  @nearby_stop_limit 3

  @type routes_map_t :: %{
          group_name: atom,
          routes: [route_with_directions]
        }

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"stop" => stop}) do
    if Laboratory.enabled?(conn, :stop_page_redesign) do
      stop =
        stop
        |> URI.decode_www_form()
        |> Repo.get_parent()

      if stop do
        routes_by_stop = Routes.Repo.by_stop(stop.id)
        grouped_routes = grouped_routes(routes_by_stop)
        routes_map = routes_map(grouped_routes, stop.id)
        json_safe_routes = json_safe_routes(routes_map)

        conn
        |> assign(:disable_turbolinks, true)
        |> assign(:stop, stop)
        |> assign(:routes, json_safe_routes)
        |> assign(:requires_google_maps?, true)
        |> async_assign_default(
          :retail_locations,
          fn ->
            stop
            |> RetailLocations.get_nearby()
            |> Enum.map(&format_retail_location/1)
          end,
          []
        )
        |> assign(:map_data, StopMap.map_info(stop, routes_map))
        |> assign(:zone_number, Zones.Repo.get(stop.id))
        |> assign(:breadcrumbs_title, breadcrumbs(stop, routes_by_stop))
        |> assign_stop_page_data()
        |> await_assign_all_default(__MODULE__)
        |> combine_stop_data()
        |> meta_description(stop, routes_by_stop)
        |> render("show.html")
      else
        check_cms_or_404(conn)
      end
    else
      render_404(conn)
    end
  end

  @spec nearby_stops(Stop.t()) :: [
          %{
            stop: Stop.t(),
            distance: float,
            routes_with_direction: [Nearby.route_with_direction()]
          }
        ]
  defp nearby_stops(%{latitude: latitude, longitude: longitude}) do
    %{latitude: latitude, longitude: longitude}
    |> Nearby.nearby_with_routes(@distance_tenth_of_a_mile, limit: @nearby_stop_limit)
    |> Enum.map(fn %{routes_with_direction: routes_with_direction} = nearby_stops ->
      %{
        nearby_stops
        | routes_with_direction:
            Enum.map(routes_with_direction, fn %{route: route} = route_with_direction ->
              %{route_with_direction | route: JsonHelpers.stringified_route(route)}
            end)
      }
    end)
  end

  @spec grouped_routes([Route.t()]) :: [{Route.gtfs_route_type(), [Route.t()]}]
  defp grouped_routes(routes) do
    routes
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&Group.sorter/1)
  end

  @spec routes_map([{Route.gtfs_route_type(), [Route.t()]}], Stop.id_t()) :: [routes_map_t]
  def routes_map(grouped_routes, stop_id) do
    Enum.map(grouped_routes, fn {group, routes} ->
      %{
        group_name: group,
        routes:
          routes
          |> schedules_for_routes(stop_id)
          |> Enum.reject(&no_directions_include_headsigns?/1)
      }
    end)
  end

  @type route_with_directions :: %{
          required(:route) => Route.t(),
          required(:directions) => [TransitNearMe.direction_data()]
        }
  @spec schedules_for_routes([Route.t()], Stop.id_t()) :: [route_with_directions | nil]
  defp schedules_for_routes(routes, stop_id),
    do: Enum.map(routes, &schedules_for_route(&1, stop_id))

  @spec schedules_for_route(Route.t(), Stop.id_t()) :: route_with_directions | nil
  defp schedules_for_route(%Route{} = route, stop_id) do
    directions =
      route.id
      |> get_schedules(stop_id)
      |> TransitNearMe.get_direction_map(now: Util.now())
      |> filter_headsigns()

    %{
      route: route,
      directions: directions
    }
  end

  defp get_schedules(route_id, stop_id) do
    schedules_fn = &Schedules.Repo.by_route_ids/2
    now = Util.now()

    [route_id]
    |> schedules_fn.(
      stop_ids: stop_id,
      min_time: TransitNearMe.format_min_time(now)
    )
    |> Enum.reject(& &1.last_stop?)
    |> case do
      [_ | _] = schedules ->
        schedules

      [] ->
        # if there are no schedules left for today, get schedules for tomorrow
        [route_id]
        |> schedules_fn.(
          stop_ids: stop_id,
          date: TransitNearMe.tomorrow_date(now)
        )
        |> Enum.reject(& &1.last_stop?)
    end
  end

  @spec filter_headsigns([TransitNearMe.direction_data()]) :: [TransitNearMe.direction_data()]
  defp filter_headsigns(directions) do
    Enum.map(directions, fn direction ->
      if any_headsign_includes_predictions?(direction) do
        %{
          direction_id: direction.direction_id,
          headsigns: Enum.reject(direction.headsigns, &(!includes_predictions?(&1)))
        }
      else
        direction
      end
    end)
  end

  @spec no_directions_include_headsigns?(route_with_directions) :: boolean
  defp no_directions_include_headsigns?(%{directions: directions}),
    do: !Enum.any?(directions, &any_headsign_includes_predictions?/1)

  @spec any_headsign_includes_predictions?(TransitNearMe.direction_data()) :: boolean
  defp any_headsign_includes_predictions?(%{headsigns: headsigns}),
    do: Enum.any?(headsigns, &includes_predictions?/1)

  defp any_headsign_includes_predictions?(_direction_with_no_headsigns), do: false

  @spec includes_predictions?(TransitNearMe.headsign_data()) :: boolean
  defp includes_predictions?(%{times: times}), do: Enum.any?(times, &(&1.prediction != nil))

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

  @type json_safe_routes :: %{
          required(:group_name) => atom,
          required(:routes) => map
        }
  @spec json_safe_routes([routes_map_t]) :: [json_safe_routes]
  defp json_safe_routes(routes_map) do
    Enum.map(routes_map, fn group_and_routes ->
      safe_routes = Enum.map(group_and_routes.routes, &json_safe_route_with_directions(&1))

      %{
        group_name: group_and_routes.group_name,
        routes: safe_routes
      }
    end)
  end

  @spec json_safe_route_with_directions(route_with_directions) :: map
  defp json_safe_route_with_directions(%{route: route, directions: directions}) do
    %{
      route: Route.to_json_safe(route),
      directions: directions
    }
  end

  @spec assign_stop_page_data(Conn.t()) :: Conn.t()
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
      suggested_transfers: nearby_stops(stop),
      tabs: [
        %HeaderTab{
          id: "info",
          name: "Station Info",
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

  @spec breadcrumbs(Stop.t(), [Route.t()]) :: [Util.Breadcrumb.t()]
  def breadcrumbs(%Stop{name: name}, []) do
    breadcrumbs_for_station_type(nil, name)
  end

  def breadcrumbs(%Stop{station?: true, name: name}, routes) do
    routes
    |> Enum.min_by(& &1.type)
    |> Route.path_atom()
    |> breadcrumbs_for_station_type(name)
  end

  def breadcrumbs(%Stop{name: name}, _routes) do
    breadcrumbs_for_station_type(nil, name)
  end

  defp breadcrumbs_for_station_type(breadcrumb_tab, name)
       when breadcrumb_tab in ~w(subway commuter-rail ferry)a do
    [
      Breadcrumb.build("Stations", stop_path(SiteWeb.Endpoint, :show, breadcrumb_tab)),
      Breadcrumb.build(name)
    ]
  end

  defp breadcrumbs_for_station_type(_, name) do
    [Breadcrumb.build(name)]
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

  @spec format_retail_location({Location.t(), float}) :: %{
          distance: String.t(),
          location: Location.t()
        }
  defp format_retail_location({%Location{} = location, distance}) do
    %{
      distance: ViewHelpers.round_distance(distance),
      location: location
    }
  end

  defp combine_stop_data(conn) do
    merged_stop_data =
      Map.put(conn.assigns.stop_page_data, :retail_locations, conn.assigns.retail_locations)

    assigns =
      conn.assigns
      |> Map.put(:stop_page_data, merged_stop_data)
      |> Map.delete(:retail_locations)

    %{conn | assigns: assigns}
  end
end
