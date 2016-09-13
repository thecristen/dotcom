defmodule Site.ScheduleController.HelpersTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleController.Helpers

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

    test "translates the type number to a string" do
      assert Helpers.route_type(0) == "Tram/Streetcar/Light Rail"
      assert Helpers.route_type(1) == "Subway/Metro"
      assert Helpers.route_type(2) == "Rail"
      assert Helpers.route_type(3) == "Bus"
      assert Helpers.route_type(4) == "Ferry"
      assert Helpers.route_type(5) == "Cable Car"
      assert Helpers.route_type(6) == "Gondola/Suspended Cable Car"
      assert Helpers.route_type(7) == "Funicular"
    end
  end
end
