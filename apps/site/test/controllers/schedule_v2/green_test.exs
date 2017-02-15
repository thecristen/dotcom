defmodule Site.ScheduleV2Controller.GreenTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.Green
  alias Alerts.{Alert, InformedEntity}

  @moduletag :external

  @green_line %Routes.Route{
    id: "Green",
    name: "Green Line",
    direction_names: %{0 => "Westbound", 1 => "Eastbound"},
    type: 0
  }

  test "assigns the route as the Green Line", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green"))
    html_response(conn, 200)
    assert conn.assigns.route == @green_line
  end

  test "assigns the date and date_time", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green"))
    html_response(conn, 200)
    assert conn.assigns.date
    assert conn.assigns.date_time
  end

  test "assigns date select and calendar", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green", date_select: "true"))
    html_response(conn, 200)
    assert conn.assigns.date_select
    assert conn.assigns.calendar
  end

  test "assigns alerts for all branches", %{conn: conn} do
    {:ok, date_time, _} = DateTime.from_iso8601("2017-02-10T11:28:02.639258-05:00")
    conn = conn
    |> assign(:date, DateTime.to_date(date_time))
    |> assign(:date_time, date_time)
    |> assign(:route, @green_line)
    |> fetch_query_params
    |> alerts(alerts_fn: fn ->
      for route_id <- GreenLine.branch_ids() do
        %Alert{
          informed_entity: [%InformedEntity{route: route_id}],
          active_period: [{nil, nil}],
          updated_at: date_time
        }
      end
    end)

    assert conn.assigns.all_alerts
    |> Enum.flat_map(& &1.informed_entity)
    |> Enum.map(& &1.route)
    |> Kernel.==(GreenLine.branch_ids())
  end

  test "assigns origin and destination", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green", origin: "place-pktrm", destination: "place-boyls"))
    assert conn.assigns.origin.id == "place-pktrm"
    assert conn.assigns.destination.id == "place-boyls"
  end

  test "assigns stops for all branches", %{conn: conn} do
    all_stops = Enum.map(get(conn, schedule_v2_path(conn, :show, "Green")).assigns.all_stops, & &1.id)

    assert "place-lake" in all_stops
    assert "place-clmnl" in all_stops
    assert "place-river" in all_stops
    assert "place-hsmnl" in all_stops
  end

  test "assigns headsigns for all branches", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green"))

    assert "Boston College" in conn.assigns.headsigns[0]
    assert "Cleveland Circle" in conn.assigns.headsigns[0]
    assert "Riverside" in conn.assigns.headsigns[0]
    assert "Heath Street" in conn.assigns.headsigns[0]

    assert "Park Street" in conn.assigns.headsigns[1]
    assert "Lechmere" in conn.assigns.headsigns[1]
    assert "North Station" in conn.assigns.headsigns[1]
    assert "Government Center" in conn.assigns.headsigns[1]
  end

  test "assigns predictions for all branches", %{conn: conn} do
    conn = conn
    |> assign(:date, ~D[2017-01-01])
    |> assign(:date_time, ~N[2017-01-01T12:00:00])
    |> assign(:origin, %Stops.Stop{id: "place-north"})
    |> assign(:destination, nil)
    |> assign(:direction_id, 0)
    |> assign(:route, @green_line)
    |> predictions(predictions_fn: fn params ->
      [%Predictions.Prediction{route_id: params[:route]}]
    end)

    assert Enum.map(conn.assigns.predictions, & &1.route_id) == GreenLine.branch_ids()
  end

  test "assigns vehicle locations for all branches", %{conn: conn} do
    conn = conn
    |> assign(:date, ~D[2017-01-01])
    |> assign(:date_time, ~N[2017-01-01T12:00:00])
    |> assign(:direction_id, 0)
    |> assign(:route, @green_line)
    |> vehicle_locations([
      schedule_for_trip_fn: fn _ -> [] end,
      location_fn: fn route_id, _ -> [
        %Vehicles.Vehicle{route_id: route_id, stop_id: "stop-#{route_id}", trip_id: "trip-#{route_id}"}
      ] end
    ])

    assert conn.assigns.vehicle_locations
    |> Map.values
    |> Enum.map(& &1.route_id)
    |> Kernel.==(GreenLine.branch_ids())
  end

  test "assigns excluded stops", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green", origin: "place-pktrm", direction_id: 0))

    assert conn.assigns.excluded_origin_stops == ExcludedStops.excluded_origin_stops(0, "Green", conn.assigns.all_stops)
    assert conn.assigns.excluded_destination_stops == ExcludedStops.excluded_destination_stops("Green", "place-pktrm")
  end

  test "assigns stop times", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green", origin: "place-pktrm"))

    assert conn.assigns.stop_times.times
  end

  test "assigns breadcrumbs", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green"))

    assert conn.assigns.breadcrumbs
  end

  test "assigns stops_on_routes", %{conn: conn} do
    conn = get(conn, schedule_v2_path(conn, :show, "Green", direction_id: 1))

    assert conn.assigns.stops_on_routes == GreenLine.stops_on_routes(1)
  end
end
