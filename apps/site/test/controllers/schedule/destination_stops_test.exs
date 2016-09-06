defmodule Site.ScheduleController.DestinationStopsTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleController.AllStops
  alias Site.ScheduleController.DestinationStops

  def conn_with_route(conn, route_id, opts) do
    conn = conn
    |> assign(:route, %Routes.Route{id: route_id})
    |> AllStops.call([])

    opts
    |> Enum.reduce(conn, fn {key, value}, conn -> assign(conn, key, value) end)
  end

  test "destination stops are not assigned if no origin is present", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: nil)
    |> DestinationStops.call([])

    refute :destination_stops in Map.keys(conn.assigns)
  end

  test "destination_stops and all_stops are the same on non-red lines", %{conn: conn} do
    conn = conn
    |> conn_with_route("Green-B", origin: "place-lake", direction_id: 1)
    |> DestinationStops.call([])

    assert conn.assigns[:destination_stops] == conn.assigns[:all_stops]
  end

  test "destination_stops and all_stops are the same on southbound red line trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: "place-alfcl", direction_id: 0)
    |> DestinationStops.call([])

    assert conn.assigns[:destination_stops] == conn.assigns[:all_stops]
  end

  test "destination_stops does not include Ashmont stops on northbound Braintree trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: "place-brntn", direction_id: 1)
    |> DestinationStops.call([])

    refute "place-smmn" in Enum.map(conn.assigns[:destination_stops], &(&1.id))
  end

  test "destination_stops does not include Braintree stops on northbound Ashmost trips", %{conn: conn} do
    conn = conn
    |> conn_with_route("Red", origin: "place-asmnl", direction_id: 1)
    |> DestinationStops.call([])

    refute "place-qamnl" in Enum.map(conn.assigns[:destination_stops], &(&1.id))
  end
end
