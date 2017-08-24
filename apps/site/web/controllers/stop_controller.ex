defmodule Site.StopController do
  use Site.Web, :controller

  plug :all_alerts

  alias Stops.Repo
  alias Stops.Stop
  alias Routes.Route
  alias Site.StopController.StopMap

  @type grouped_stations :: {Route.t, [Stop.t]}

  def index(conn, _params) do
    redirect conn, to: stop_path(conn, :show, :subway)
  end

  def show(conn, %{"id" => mode}) when mode in ["subway", "commuter_rail", "ferry"] do
    mode_atom = String.to_existing_atom(mode)
    {mattapan, stop_info} = get_stop_info(mode_atom)
    conn
    |> async_assign(:mode_hubs, fn -> HubStops.mode_hubs(mode, stop_info) end)
    |> async_assign(:route_hubs, fn -> HubStops.route_hubs(stop_info) end)
    |> assign(:stop_info, stop_info)
    |> assign(:mattapan, mattapan)
    |> assign(:mode, mode_atom)
    |> assign(:breadcrumbs, [Breadcrumb.build("Stations")])
    |> await_assign_all
    |> render("index.html")
  end
  def show(conn, %{"tab" => "schedule", "id" => id} = params) do
    redirect conn, to: stop_path(conn, :show, id, %{params | "tab" => "departures"})
  end
  def show(%Plug.Conn{query_params: query_params} = conn, %{"id" => id}) do
    stop = id
    |> URI.decode_www_form
    |> Repo.get!

    conn
    |> async_assign(:grouped_routes, fn -> grouped_routes(stop.id) end)
    |> async_assign(:zone_number, fn -> Zones.Repo.get(stop.id) end)
    |> assign(:breadcrumbs, breadcrumbs(stop))
    |> assign(:tab, tab_value(query_params["tab"]))
    |> tab_assigns(stop)
    |> await_assign_all()
    |> render("show.html", stop: stop)
  end

  @spec grouped_routes(String.t) :: [{Route.gtfs_route_type, Route.t}]
  defp grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&Routes.Group.sorter/1)
  end

  @spec breadcrumbs(Stop.t) :: [Util.Breadcrumb.t]
  defp breadcrumbs(%Stop{station?: true, name: name, id: id}) do
    breadcrumb_tab = id
      |> Routes.Repo.by_stop()
      |> Enum.min_by(& &1.type)
      |> Routes.Route.type_atom

    breadcrumbs_for_station_type(breadcrumb_tab, name)
  end
  defp breadcrumbs(%Stop{name: name}) do
    breadcrumbs_for_station_type(nil, name)
  end

  defp breadcrumbs_for_station_type(breadcrumb_tab, name)
  when breadcrumb_tab in ~w(subway commuter_rail ferry)a do
    [
      Breadcrumb.build("Stations", stop_path(Site.Endpoint, :show, breadcrumb_tab)),
      Breadcrumb.build(name)
    ]
  end
  defp breadcrumbs_for_station_type(_, name) do
    [Breadcrumb.build(name)]
  end

  # Determine which tab should be displayed
  @spec tab_value(String.t | nil) :: String.t
  defp tab_value("departures"), do: "departures"
  defp tab_value(_), do: "info"

  defp tab_assigns(%{assigns: %{tab: "info", all_alerts: alerts}} = conn, stop) do
    conn
    |> async_assign(:fare_name, fn -> fare_name(stop) end)
    |> async_assign(:terminal_stations, fn -> terminal_stations(stop) end)
    |> async_assign(:fare_sales_locations, fn -> Fares.RetailLocations.get_nearby(stop) end)
    |> assign(:access_alerts, access_alerts(alerts, stop))
    |> assign(:requires_google_maps?, true)
    |> assign(:map_info, StopMap.map_info(stop))
    |> assign(:stop_alerts, stop_alerts(alerts, stop))
    |> await_assign_all()
  end
  defp tab_assigns(%{assigns: %{tab: "departures", all_alerts: alerts}} = conn, stop) do
    conn
    |> async_assign(:stop_schedule, fn -> stop_schedule(stop.id, conn.assigns.date) end)
    |> async_assign(:stop_predictions, fn -> stop_predictions(stop.id) end)
    |> assign(:stop_alerts, stop_alerts(alerts, stop))
    |> await_assign_all(10_000)
    |> assign_upcoming_route_departures()
  end

  defp assign_upcoming_route_departures(conn) do
    route_time_list = conn.assigns.stop_predictions
    |> UpcomingRouteDepartures.build_mode_list(conn.assigns.stop_schedule, conn.assigns.date_time)
    |> Enum.sort_by(&Routes.Group.sorter/1)

    assign(conn, :upcoming_route_departures, route_time_list)
  end

  defp fare_name(stop) do
    stop
    |> terminal_stations
    |> Enum.reject(fn {_mode, terminal} -> terminal == "" end)
    |> Enum.map(&lookup_fare(&1, stop))
    |> List.first
  end

  defp lookup_fare({mode, terminus}, stop) do
     Fares.fare_for_stops(Route.type_atom(mode), terminus, stop.id)
  end

  # Returns the last station on the commuter rail lines traveling through the given stop, or the empty string
  # if the stop doesn't serve commuter rail. Note that this assumes that all CR lines at a station have the
  # same terminal, which is currently true but could conceivably change in the future.

  @spec terminal_stations(Stop.t) :: %{2 => String.t, 4 => String.t}
  defp terminal_stations(stop) do
    Map.new([2, 4], &{&1, terminal_station_for_type(stop.id, &1)})
  end

  defp terminal_station_for_type(stop_id, type) do
    stop_id
    |> Routes.Repo.by_stop(type: type)
    |> do_terminal_stations(type)
  end

  # Filter out non-CR stations.
  defp do_terminal_stations([route | _], 2) do
    route.id
    |> Stops.Repo.by_route(0)
    |> List.first
    |> Map.get(:id)
  end
  defp do_terminal_stations([route], 4) do
    case Stops.Repo.by_route(route.id, 0) do
      [terminal_stop, _next_stop] -> terminal_stop.id
      _ -> ""
    end
  end
  defp do_terminal_stations(_routes, _type), do: ""

  @spec access_alerts([Alerts.Alert.t], Stop.t) :: [Alerts.Alert.t]
  def access_alerts(alerts, stop) do
    alerts
    |> Enum.filter(&(&1.effect == :access_issue))
    |> stop_alerts(stop)
  end

  @spec stop_alerts([Alerts.Alert.t], Stop.t) :: [Alerts.Alert.t]
  def stop_alerts(alerts, stop) do
    Alerts.Stop.match(alerts, stop.id)
  end

  @spec stop_schedule(String.t, DateTime.t) :: [Schedules.Schedule.t]
  defp stop_schedule(stop_id, date) do
    Schedules.Repo.schedule_for_stop(stop_id, date: date)
  end

  @spec stop_predictions(String.t) :: [Predictions.Prediction.t]
  defp stop_predictions(stop_id) do
    Predictions.Repo.all(stop: stop_id)
  end

  defp all_alerts(conn, _opts) do
    assign(conn, :all_alerts, Alerts.Repo.all(conn.assigns.date_time))
  end

  @spec get_stop_info(Route.gtfs_route_type) :: {DetailedStopGroup.t, [DetailedStopGroup.t]}
  defp get_stop_info(mode) do
    mode
    |> DetailedStopGroup.from_mode()
    |> separate_mattapan()
  end

  # Separates mattapan from stop_info list
  @spec separate_mattapan([DetailedStopGroup.t]) :: {DetailedStopGroup.t, [DetailedStopGroup.t]}
  defp separate_mattapan(stop_info) do
    case Enum.find(stop_info, fn {route, _stops} -> route.id == "Mattapan" end) do
      nil -> {nil, stop_info}
      mattapan -> {mattapan, List.delete(stop_info, mattapan)}
    end
  end
end
