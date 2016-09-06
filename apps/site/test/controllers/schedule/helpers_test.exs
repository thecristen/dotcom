defmodule Site.ScheduleController.HelpersTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleController.Helpers

  test "assign_all_stops deduplicates red line stops", %{conn: conn} do
    conn = conn
    |> assign(:date, nil)
    |> assign(:direction_id, 1)
    |> Helpers.assign_all_stops("Red")

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
  end

  describe "destination stops" do
    test "destination stops are not assigned if no origin is present", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Red")
      refute :destination_stops in Map.keys(conn.assigns)
    end

    test "destination_stops and all_stops are the same on non-red lines", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Green-B", origin: "place-lake", direction_id: 1)
      assert conn.assigns[:destination_stops] == conn.assigns[:all_stops]
    end

    test "destination_stops and all_stops are the same on southbound red line trips", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Red", origin: "place-alfcl", direction_id: 0)
      assert conn.assigns[:destination_stops] == conn.assigns[:all_stops]
    end

    test "destination_stops does not include Ashmont stops on northbound Braintree trips", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Red", origin: "place-brntn", direction_id: 1)
      refute "place-smmn" in Enum.map(conn.assigns[:destination_stops], &(&1.id))
    end

    test "destination_stops does not include Braintree stops on northbound Ashmost trips", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Red", origin: "place-asmnl", direction_id: 1)
      refute "place-qamnl" in Enum.map(conn.assigns[:destination_stops], &(&1.id))
    end
  end

  describe "assign_datetime" do
    test "if a date is specified, uses noon on that date", %{conn: conn} do
      conn = conn
      |> assign(:date, ~D[1970-01-01])
      |> Helpers.assign_datetime

      noon = Timex.to_datetime({{1970, 1, 1}, {12, 0, 0}}, "America/New_York")
      assert conn.assigns[:datetime] == noon
    end

    test "if trips are present, uses the time of the first scheduled stop", %{conn: conn} do
      time = Timex.now
      |> Timex.shift(hours: 12)

      conn = conn
      |> assign(:trip_schedule, [%Schedules.Schedule{time: time}])
      |> Helpers.assign_datetime

      assert conn.assigns[:datetime] == time
    end

    test "if the date is today, uses now", %{conn: conn} do
      now = Timex.now

      conn = conn
      |> assign(:date, now |> Timex.to_date)
      |> Helpers.assign_datetime

      assert Timex.between?(
        conn.assigns[:datetime],
        Timex.shift(now, seconds: -1),
        Timex.shift(now, seconds: 1))
    end
  end
end
