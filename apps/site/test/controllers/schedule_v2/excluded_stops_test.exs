defmodule Site.ScheduleV2Controller.ExcludedStopsTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleV2Controller.AllStops
  alias Site.ScheduleV2Controller.ExcludedStops
  alias Stops.Stop

  defp conn_with_route(conn, route_id, opts) do
    conn = conn
    |> assign(:date, Util.service_date())
    |> assign(:route, %Routes.Route{id: route_id})

    conn =  Enum.reduce(opts, conn, fn {key, value}, conn -> assign(conn, key, value) end)

    AllStops.call(conn, [])
  end

  test "exclusions use normal lines on non-red lines", %{conn: conn} do
    conn = conn
    |> conn_with_route("Green-B", origin: %Stop{id: "place-lake"}, direction_id: 1)
    |> ExcludedStops.call([])

    assert conn.assigns.excluded_origin_stops == ["place-pktrm"]
    assert conn.assigns.excluded_destination_stops == []
  end

  test "exclusions use the direction_id to exclude the last stop", %{conn: conn} do
    conn = conn
    |> conn_with_route("Green-B", origin: %Stop{id: "place-pktrm"}, direction_id: 0)
    |> ExcludedStops.call([])

    assert conn.assigns.excluded_origin_stops == ["place-lake"]
    assert conn.assigns.excluded_destination_stops == []
  end

  test "destination_stops and all_stops are the same on southbound red line trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: %Stop{id: "place-alfcl"}, direction_id: 0)
    |> ExcludedStops.call([])

    assert conn.assigns.excluded_origin_stops == ["place-brntn", "place-asmnl"]
    assert conn.assigns.excluded_destination_stops == []
  end

  test "destination_stops does not include Ashmont stops on northbound Braintree trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: %Stop{id: "place-brntn"}, direction_id: 1)
    |> ExcludedStops.call([])

    assert "place-smmnl" in conn.assigns.excluded_destination_stops
  end

  test "destination_stops does not include Braintree stops on northbound Ashmont trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: %Stop{id: "place-asmnl"}, direction_id: 1)
    |> ExcludedStops.call([])

    assert "place-qamnl" in conn.assigns.excluded_destination_stops
  end

  test "assigns both to an empty list if there aren't any stops or a route", %{conn: conn} do
    result = ExcludedStops.call(conn, []).assigns

    assert result.excluded_origin_stops == []
    assert result.excluded_destination_stops == []
  end
end
