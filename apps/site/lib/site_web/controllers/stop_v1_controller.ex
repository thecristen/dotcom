defmodule SiteWeb.StopV1Controller do
  @moduledoc """
  Page for display of information about in individual stop or station.
  """
  use SiteWeb, :controller

  plug(:alerts)
  plug(SiteWeb.Plugs.AlertsByTimeframe)
  alias Alerts.Repo, as: AlertsRepo
  alias Alerts.Stop, as: AlertsStop
  alias Fares.RetailLocations
  alias Routes.{Group, Route}
  alias SiteWeb.StopController.StopV1Map
  alias Stops.{Repo, Stop}
  alias Util.AndOr

  @type grouped_stations :: {Route.t(), [Stop.t()]}

  def index(conn, _params) do
    redirect(conn, to: stop_v1_path(conn, :show, :subway))
  end

  def show(conn, %{"id" => mode}) when mode in ["subway", "commuter-rail", "ferry"] do
    mode_atom = Route.type_atom(mode)
    {mattapan, stop_info} = get_stop_info()

    conn
    |> async_assign_default(:mode_hubs, fn -> HubStops.mode_hubs(mode_atom, stop_info) end, [])
    |> async_assign_default(:route_hubs, fn -> HubStops.route_hubs(stop_info) end, [])
    |> assign(:stop_info, stop_info)
    |> assign(:mattapan, mattapan)
    |> assign(:mode, mode_atom)
    |> assign(:breadcrumbs, [Breadcrumb.build("Stations")])
    |> assign(:requires_google_maps?, true)
    |> await_assign_all_default(__MODULE__)
    |> render("index.html")
  end

  def show(conn, %{"tab" => "schedule", "id" => id} = params) do
    redirect(conn, to: stop_v1_path(conn, :show, id, %{params | "tab" => "departures"}))
  end

  def show(%Plug.Conn{query_params: query_params} = conn, %{"id" => id}) do
    stop =
      id
      |> URI.decode_www_form()
      |> Repo.get()

    if stop do
      routes = Routes.Repo.by_stop(stop.id)

      conn
      |> async_assign_default(:grouped_routes, fn -> grouped_routes(routes) end, [])
      |> assign(:fare_types, fare_types(routes))
      |> async_assign_default(:zone_number, fn -> Zones.Repo.get(stop.id) end, nil)
      |> assign(:breadcrumbs, breadcrumbs(stop, routes))
      |> assign(:tab, tab_value(query_params["tab"]))
      |> tab_assigns(stop, routes)
      |> meta_description(stop, routes)
      |> await_assign_all_default(__MODULE__)
      |> render("show.html", stop: stop)
    else
      check_cms_or_404(conn)
    end
  end

  @doc "Redirect users who type in a URL with a slash to the correct URL"
  def stop_with_slash_redirect(conn, %{"path" => path}) do
    real_id = Enum.join(path, "/")

    conn
    |> redirect(to: stop_v1_path(conn, :show, real_id))
    |> halt
  end

  @spec coerce_sl_rapid_transit_to_subway(Route.t()) :: Route.t()
  defp coerce_sl_rapid_transit_to_subway(route) do
    if Fares.silver_line_rapid_transit?(route.id) do
      %{route | type: 1}
    else
      route
    end
  end

  @spec grouped_routes([Route.t()]) :: [{Route.gtfs_route_type(), Route.t()}]
  defp grouped_routes(routes) do
    routes
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&Group.sorter/1)
  end

  @spec fare_types([Route.t()]) :: [Route.id_t()]
  defp fare_types(routes) do
    routes
    |> Enum.map(&coerce_sl_rapid_transit_to_subway/1)
    |> Enum.map(&Route.type_atom/1)
    |> Enum.uniq()
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
      Breadcrumb.build("Stations", stop_v1_path(SiteWeb.Endpoint, :show, breadcrumb_tab)),
      Breadcrumb.build(name)
    ]
  end

  defp breadcrumbs_for_station_type(_, name) do
    [Breadcrumb.build(name)]
  end

  # Determine which tab should be displayed
  @spec tab_value(String.t() | nil) :: String.t()
  defp tab_value("departures"), do: "departures"
  defp tab_value("alerts"), do: "alerts"
  defp tab_value(_), do: "info"

  @spec tab_assigns(Plug.Conn.t(), Stop.t(), [Route.t()]) :: Plug.Conn.t()
  defp tab_assigns(%{assigns: %{tab: "info"}} = conn, stop, routes) do
    conn
    |> async_assign_default(:fare_name, fn -> fare_name(stop, routes) end, nil)
    |> async_assign_default(:terminal_stations, fn -> terminal_stations(routes) end, %{})
    |> async_assign_default(:fare_sales_locations, fn -> RetailLocations.get_nearby(stop) end, [])
    |> assign(:requires_google_maps?, true)
    |> assign(:map_info, StopV1Map.map_info(stop))
    |> await_assign_all_default(__MODULE__)
  end

  defp tab_assigns(%{assigns: %{tab: "departures"}} = conn, stop, _routes) do
    conn
    |> async_assign_default(
      :stop_schedule,
      fn -> stop_schedule(stop.id, conn.assigns.date) end,
      []
    )
    |> async_assign_default(:stop_predictions, fn -> stop_predictions(stop.id) end, [])
    |> await_assign_all_default(__MODULE__, 10_000)
    |> assign_upcoming_route_departures()
  end

  defp tab_assigns(%{assigns: %{tab: "alerts"}} = conn, _stop, _routes) do
    conn
  end

  defp assign_upcoming_route_departures(conn) do
    route_time_list =
      conn.assigns.stop_predictions
      |> UpcomingRouteDepartures.build_mode_list(
        conn.assigns.stop_schedule,
        conn.assigns.date_time
      )
      |> Enum.sort_by(&Group.sorter/1)

    assign(conn, :upcoming_route_departures, route_time_list)
  end

  defp fare_name(stop, routes) do
    routes
    |> terminal_stations
    |> Enum.reject(fn {_mode, terminal} -> terminal == "" end)
    |> Enum.find_value(&lookup_fare(&1, stop))
  end

  defp lookup_fare({mode, terminus}, stop) do
    case Fares.fare_for_stops(Route.type_atom(mode), terminus, stop.id) do
      {:ok, name} -> name
      :error -> nil
    end
  end

  # Returns the last station on the commuter rail lines traveling through the given stop, or the empty string
  # if none of the routes are commuter rail. Note that this assumes that all CR lines at a station have the
  # same terminal, which is currently true but could conceivably change in the future.

  @spec terminal_stations([Route.t()]) :: %{2 => String.t(), 4 => String.t()}
  defp terminal_stations(routes) do
    Map.new([2, 4], &{&1, terminal_station_for_type(routes, &1)})
  end

  defp terminal_station_for_type(routes, type) do
    routes
    |> Enum.filter(fn route -> route.type == type end)
    |> do_terminal_stations(type)
  end

  # Filter out non-CR stations.
  defp do_terminal_stations([route | _], 2) do
    route.id
    |> Repo.by_route(0)
    |> List.first()
    |> Map.get(:id)
  end

  defp do_terminal_stations([route], 4) do
    case Repo.by_route(route.id, 0) do
      [terminal_stop, _next_stop] -> terminal_stop.id
      _ -> ""
    end
  end

  defp do_terminal_stations(_routes, _type), do: ""

  @spec stop_schedule(String.t(), DateTime.t()) :: [Schedules.Schedule.t()]
  defp stop_schedule(stop_id, date) do
    Schedules.Repo.schedule_for_stop(stop_id, date: date)
  end

  @spec stop_predictions(String.t()) :: [Predictions.Prediction.t()]
  defp stop_predictions(stop_id) do
    Predictions.Repo.all(stop: stop_id)
  end

  defp alerts(%{assigns: %{alerts: alerts}} = conn, _opts) do
    assign(conn, :all_alerts_count, length(alerts))
  end

  defp alerts(%{path_params: %{"id" => id}} = conn, _opts) do
    stop_id = URI.decode_www_form(id)

    alerts =
      conn.assigns.date_time
      |> AlertsRepo.all()
      |> AlertsStop.match(stop_id)

    conn
    |> assign(:alerts, alerts)
    |> assign(:all_alerts_count, length(alerts))
  end

  defp alerts(conn, _opts) do
    assign(conn, :alerts, AlertsRepo.all(conn.assigns.date_time))
  end

  @spec get_stop_info :: {DetailedStopGroup.t(), [DetailedStopGroup.t()]}
  defp get_stop_info do
    [:subway, :commuter_rail, :ferry]
    |> Task.async_stream(&DetailedStopGroup.from_mode/1)
    |> Enum.flat_map(fn {:ok, stops} -> stops end)
    |> separate_mattapan()
  end

  # Separates mattapan from stop_info list
  @spec separate_mattapan([DetailedStopGroup.t()]) ::
          {DetailedStopGroup.t(), [DetailedStopGroup.t()]}
  defp separate_mattapan(stop_info) do
    case Enum.find(stop_info, fn {route, _stops} -> route.id == "Mattapan" end) do
      nil -> {nil, stop_info}
      mattapan -> {mattapan, List.delete(stop_info, mattapan)}
    end
  end

  defp meta_description(conn, stop, routes) do
    conn
    |> assign(:meta_description, "Station serving MBTA #{lines(routes)} lines#{location(stop)}.")
  end

  defp lines(routes) do
    routes
    |> Enum.map(&(&1.type |> Route.type_atom() |> Route.type_name()))
    |> Enum.uniq()
    |> AndOr.join(:and)
  end

  defp location(stop) do
    if stop.address && stop.address != "" do
      " at #{stop.address}"
    else
      ""
    end
  end
end
