defmodule Site.ScheduleV2Controller.Green do
  use Site.Web, :controller

  alias Site.ScheduleV2Controller, as: SV2C

  plug :route
  plug :tab
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.ScheduleController.DatePicker
  plug :alerts
  plug Site.ScheduleV2Controller.Defaults
  plug :stops_on_routes
  plug :all_stops
  plug Site.ScheduleV2Controller.OriginDestination
  plug :headsigns
  plug :schedules
  plug :vehicle_locations
  plug :predictions
  plug Site.ScheduleV2Controller.ExcludedStops
  plug Site.ScheduleV2Controller.StopTimes
  plug :validate_stop_times
  plug :hide_destination_selector
  plug Site.ScheduleV2Controller.TripInfo
  plug Site.ScheduleController.RouteBreadcrumbs
  plug :tab_assigns

  def green(conn, _params) do
    conn
    |> render(Site.ScheduleV2View, "show.html")
  end

  defp tab(conn, _opts) do
    tab = case conn.params["tab"] do
      "line" ->
        "line"
      _ ->
        "trip-view"
    end
    conn
    |> assign(:tab, tab)
  end

  def route(conn, _params) do
    assign(conn, :route, GreenLine.green_line())
  end

  def stops_on_routes(%Plug.Conn{assigns: %{direction_id: direction_id}} = conn, _opts) do
    assign(conn, :stops_on_routes, GreenLine.stops_on_routes(direction_id))
  end

  def all_stops(%Plug.Conn{assigns: %{stops_on_routes: stops_on_routes}} = conn, _params) do
    assign(conn, :all_stops, GreenLine.all_stops(stops_on_routes))
  end

  def headsigns(conn, _opts) do
    headsigns = GreenLine.branch_ids()
    |> Enum.map(&Routes.Repo.headsigns/1)
    |> Enum.reduce(%{}, & Map.merge(&1, &2, fn (_k, v1, v2) -> Enum.uniq(v1 ++ v2) end))

    assign(conn, :headsigns, headsigns)
  end

  def schedules(%Plug.Conn{assigns: %{origin: nil}} = conn, _) do
    conn
  end
  def schedules(conn, opts) do
    schedules = conn
    |> conn_with_branches
    |> Enum.flat_map(fn conn ->
      call_plug(conn, Site.ScheduleV2Controller.Schedules, opts).assigns.schedules
    end)
    |> Enum.sort_by(fn
      {s1, _s2} -> s1.time
      schedule -> schedule.time
    end)

    conn
    |> assign(:schedules, schedules)
    |> Site.ScheduleV2Controller.Schedules.assign_frequency_table(schedules)
  end

  def predictions(conn, opts) do
    predictions = conn
    |> conn_with_branches
    |> Enum.flat_map(fn conn ->
      call_plug(conn, Site.ScheduleV2Controller.Predictions, opts).assigns.predictions
    end)

    assign(conn, :predictions, predictions)
  end

  def alerts(conn, opts) do
    {all_alerts, alerts, upcoming_alerts} = conn
    |> conn_with_branches
    |> Enum.map(fn conn ->
      with_alerts = call_plug(conn, Site.Plugs.Alerts, opts).assigns
      {with_alerts.all_alerts, with_alerts.alerts, with_alerts.upcoming_alerts}
    end)
    |> Enum.reduce({MapSet.new, MapSet.new, MapSet.new}, fn {all, alerts, upcoming}, {acc_all, acc_alerts, acc_upcoming} ->
      {
        MapSet.union(MapSet.new(all), acc_all),
        MapSet.union(MapSet.new(alerts), acc_alerts),
        MapSet.union(MapSet.new(upcoming), acc_upcoming)
      }
    end)

    conn
    |> assign(:all_alerts, MapSet.to_list(all_alerts))
    |> assign(:alerts, MapSet.to_list(alerts))
    |> assign(:upcoming_alerts, MapSet.to_list(upcoming_alerts))
  end

  def vehicle_locations(conn, opts) do
    vehicle_locations = conn
    |> conn_with_branches
    |> Enum.map(fn conn ->
      call_plug(conn, Site.ScheduleV2Controller.VehicleLocations, opts).assigns.vehicle_locations
    end)
    |> Enum.reduce(%{}, &Map.merge/2)

    assign(conn, :vehicle_locations, vehicle_locations)
  end

  @doc """

  For a few westbound stops, we don't have trip predictions, only how far
  away the train is. In those cases, we disabled the destination selector
  since we can't match pairs of trips.

  """
  def hide_destination_selector(%{assigns: %{direction_id: 0, origin: %{id: stop_id}}} = conn, [])
  when stop_id in ["place-spmnl", "place-north", "place-haecl", "place-gover", "place-pktrm", "place-boyls"] do
    assign(conn, :hide_destination_selector?, true)
  end
  def hide_destination_selector(conn, []) do
    conn
  end

  @doc """

  If we built an empty stop times list, but we had predictions for the
  origin, then redirect the user away from their selected destination so they
  at least get partial results.

  """
  def validate_stop_times(%{assigns: %{destination: nil}} = conn, []) do
    conn
  end
  def validate_stop_times(%{assigns: %{stop_times: %StopTimeList{times: [_ | _]}}} = conn, []) do
    conn
  end
  def validate_stop_times(conn, []) do
    origin_predictions = conn.assigns.predictions |> Enum.find(& &1.stop.id == conn.assigns.origin.id)
    if is_nil(origin_predictions) do
      conn
    else
      url = UrlHelpers.update_url(conn, destination: nil)
      conn
      |> redirect(to: url)
      |> halt
    end
  end

  defp call_plug(conn, module, opts) do
    module.call(conn, module.init(opts))
  end

  defp conn_with_branches(conn) do
    GreenLine.branch_ids()
    |> Enum.map(fn route_id ->
      %{conn |
        assigns: %{conn.assigns | route: Routes.Repo.get(route_id)},
        params: Map.put(conn.params, "route", route_id)
       }
    end)
  end

  defmacrop call_plug(conn, module) do
    opts = Macro.expand(module, __ENV__).init([])
    quote do
      unquote(module).call(unquote(conn), unquote(opts))
    end
  end

  defp tab_assigns(%Plug.Conn{assigns: %{tab: "line"}} = conn, _opts) do
    conn
    |> call_plug(SV2C.HoursOfOperation)
    |> call_plug(SV2C.NextThreeHolidays)
    |> call_plug(SV2C.Line)
  end
  defp tab_assigns(conn, _opts), do: conn
end
