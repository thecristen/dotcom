defmodule Site.ScheduleController.DestinationStopsTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleController.AllStops
  alias Site.ScheduleController.DestinationStops

  def conn_with_route(conn, route_id, opts) do
    conn = conn
    |> assign(:route, %Routes.Route{id: route_id})

    conn = opts
    |> Enum.reduce(conn, fn {key, value}, conn -> assign(conn, key, value) end)

    conn
    |> AllStops.call([])
  end

  test "destination stops are assigned from @from if no origin is present", %{conn: conn} do
    conn = conn
    |> conn_with_route("7", origin: nil, from: %{id: "place-sstat"})
    |> DestinationStops.call([])

    assert :excluded_origin_stops in Map.keys(conn.assigns)
    assert :excluded_destination_stops in Map.keys(conn.assigns)
  end

  test "exclusions use normal lines on non-red lines", %{conn: conn} do
    conn = conn
    |> conn_with_route("Green-B", origin: "place-park", direction_id: 1)
    |> DestinationStops.call([])

    assert conn.assigns.excluded_origin_stops == ["place-lech"]
    assert conn.assigns.excluded_destination_stops == []
  end

  test "exclusions use the direction_id to exclude the last stop", %{conn: conn} do
    conn = conn
    |> conn_with_route("Green-B", origin: "place-park", direction_id: 0)
    |> DestinationStops.call([])

    assert conn.assigns.excluded_origin_stops == ["place-lake"]
    assert conn.assigns.excluded_destination_stops == []
  end

  test "destination_stops and all_stops are the same on southbound red line trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: "place-alfcl", direction_id: 0)
    |> DestinationStops.call([])

    assert conn.assigns.excluded_origin_stops == ["place-brntn", "place-asmnl"]
    assert conn.assigns.excluded_destination_stops == []
  end

  test "destination_stops does not include Ashmont stops on northbound Braintree trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: "place-brntn", direction_id: 1)
    |> DestinationStops.call([])

    assert "place-smmnl" in conn.assigns.excluded_destination_stops
  end

  test "destination_stops does not include Braintree stops on northbound Ashmost trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: "place-asmnl", direction_id: 1)
    |> DestinationStops.call([])

    assert "place-qamnl" in conn.assigns.excluded_destination_stops
  end
end
