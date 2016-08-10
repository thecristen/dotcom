defmodule Site.ScheduleController.HelpersTest do
  use Site.ConnCase, async: true

  test "assign_all_stops deduplicates red line stops", %{conn: conn} do
    conn = conn
    |> assign(:date, nil)
    |> assign(:direction_id, 1)
    |> Site.ScheduleController.Helpers.assign_all_stops("Red")

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
  end

  describe "destination stops" do
    test "destination stops are not assigned if no origin is present", %{conn: conn} do
      conn = get conn, schedule_path(conn, :index, route: "Red")
      refute :destination_stops in Map.keys(conn.assigns)
    end

    test "destination_stops and all_stops are the same on non-red lines", %{conn: conn} do
      conn = get conn, schedule_path(conn, :index, route: "Green-B", origin: "place-lake", direction_id: 1)
      assert conn.assigns[:destination_stops] == conn.assigns[:all_stops]
    end

    test "destination_stops and all_stops are the same on southbound red line trips", %{conn: conn} do
      conn = get conn, schedule_path(conn, :index, route: "Red", origin: "place-alfcl", direction_id: 0)
      assert conn.assigns[:destination_stops] == conn.assigns[:all_stops]
    end

    test "destination_stops does not include Ashmont stops on northbound Braintree trips", %{conn: conn} do
      conn = get conn, schedule_path(conn, :index, route: "Red", origin: "place-brntn", direction_id: 1)
      refute "place-smmn" in Enum.map(conn.assigns[:destination_stops], &(&1.id))
    end

    test "destination_stops does not include Braintree stops on northbound Ashmost trips", %{conn: conn} do
      conn = get conn, schedule_path(conn, :index, route: "Red", origin: "place-asmnl", direction_id: 1)
      refute "place-qamnl" in Enum.map(conn.assigns[:destination_stops], &(&1.id))
    end
  end
end
