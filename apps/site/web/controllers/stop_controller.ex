defmodule Site.StopController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.Plugs.Alerts, upcoming?: false

  alias Stops.Repo
  alias Stops.Stop
  alias Routes.Route
  alias Site.StopController.ModeController

  def index(conn, _params) do
    redirect conn, to: stop_path(conn, :show, :subway)
  end

  def show(conn, %{"id" => mode}) when mode in ["subway", "commuter_rail", "ferry"] do
    ModeController.show(conn, String.to_existing_atom(mode))
  end
  def show(conn, %{"id" => id} = params) do
    stop = id
    |> URI.decode_www_form
    |> Repo.get!

    conn
    |> async_assign(:grouped_routes, fn -> grouped_routes(stop.id) end)
    |> assign(:breadcrumbs, breadcrumbs(stop))
    |> assign(:tab, tab_value(params["tab"]))
    |> tab_assigns(stop)
    |> await_assign(:grouped_routes)
    |> render("show.html", stop: stop)
  end

  @spec grouped_routes(String.t) :: [{Route.gtfs_route_type, Route.t}]
  defp grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&sorter/1)
  end

  @spec sorter({Route.gtfs_route_type, Route.t}) :: non_neg_integer
  defp sorter({:commuter_rail, _}), do: 0
  defp sorter({:subway, _}), do: 1
  defp sorter({:bus, _}), do: 2
  defp sorter({:ferry, _}), do: 3

  @spec breadcrumbs(Stop.t) :: [{String.t, String.t} | String.t]
  defp breadcrumbs(%Stop{station?: true, name: name}) do
    [{stop_path(Site.Endpoint, :index), "Stations"}, name]
  end
  defp breadcrumbs(%Stop{name: name}) do
    [name]
  end

  # Determine which tab should be displayed
  @spec tab_value(String.t | nil) :: String.t
  defp tab_value("schedule"), do: "schedule"
  defp tab_value(_), do: "info"

  defp tab_assigns(%{assigns: %{tab: "info", all_alerts: alerts}} = conn, stop) do
    conn
    |> assign(:zone_name, Fares.calculate("1A", Zones.Repo.get(stop.id)))
    |> assign(:terminal_station, terminal_station(stop))
    |> assign(:fare_sales_locations, Fares.RetailLocations.get_nearby(stop))
    |> assign(:access_alerts, access_alerts(alerts, stop))
    |> assign(:requires_google_maps?, true)
  end
  defp tab_assigns(%{assigns: %{tab: "schedule", all_alerts: alerts}} = conn, stop) do
    conn
    |> async_assign(:stop_schedule, fn -> stop_schedule(stop.id, conn.assigns.date) end)
    |> assign(:stop_predictions, stop_predictions(stop.id))
    |> assign(:stop_alerts, stop_alerts(alerts, stop))
    |> await_assign(:stop_schedule)
    |> assign_upcoming_route_departures()
  end

  defp assign_upcoming_route_departures(conn) do
    route_time_list = conn.assigns.stop_predictions
    |> UpcomingRouteDepartures.build_mode_list(conn.assigns.stop_schedule, conn.assigns.date_time)
    |> Enum.sort_by(&sorter/1)

    assign(conn, :upcoming_route_departures, route_time_list)
  end

  # Returns the last station on the commuter rail lines traveling through the given stop, or the empty string
  # if the stop doesn't serve commuter rail. Note that this assumes that all CR lines at a station have the
  # same terminal, which is currently true but could conceivably change in the future.
  @spec terminal_station(Stop.t) :: String.t
  defp terminal_station(stop) do
    stop.id
    |> Routes.Repo.by_stop(type: 2)
    |> do_terminal_station
  end

  # Filter out non-CR stations.
  defp do_terminal_station([]), do: ""
  defp do_terminal_station([route | _]) do
    terminal = route.id
    |> Stops.Repo.by_route(0)
    |> List.first
    terminal.id
  end

  @spec access_alerts([Alerts.Alert.t], Stop.t) :: [Alerts.Alert.t]
  def access_alerts(alerts, stop) do
    alerts
    |> Enum.filter(&(&1.effect_name == "Access Issue"))
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
end
