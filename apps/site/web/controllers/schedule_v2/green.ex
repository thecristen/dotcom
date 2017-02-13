defmodule Site.ScheduleV2Controller.Green do
  use Site.Web, :controller

  @route %Routes.Route{
    id: "Green",
    name: "Green Line",
    direction_names: %{0 => "Westbound", 1 => "Eastbound"},
    type: 0
  }

  plug :route
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
  # TODO: https://app.asana.com/0/234523466737812/269737361805728
  # makes adding TripInfo here essentially useless; it either assigns
  # trip_info to nil or creates a looping redirect.
  # plug Site.ScheduleV2Controller.TripInfo
  plug Site.ScheduleController.RouteBreadcrumbs

  def green(conn, _params) do
    conn
    |> assign(:tab, "trip-view")
    |> assign(:trip_info, nil)
    |> render(Site.ScheduleV2View, "show.html")
  end

  def route(conn, _params) do
    assign(conn, :route, @route)
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
end
