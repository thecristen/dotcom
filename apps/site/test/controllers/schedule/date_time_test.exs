defmodule Site.ScheduleController.DateTimeTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleController.DateTime

  test "if a date is specified, uses noon on that date", %{conn: conn} do
    conn = conn
    |> assign(:date, ~D[1970-01-01])
    |> DateTime.call([])

    noon = Timex.to_datetime({{1970, 1, 1}, {12, 0, 0}}, "America/New_York")
    assert conn.assigns[:datetime] == noon
  end

  test "if trips are present, uses the time of the first scheduled stop", %{conn: conn} do
    time = Timex.now
    |> Timex.shift(hours: 12)

    conn = conn
    |> assign(:trip_schedule, [%Schedules.Schedule{time: time}])
    |> DateTime.call([])

    assert conn.assigns[:datetime] == time
  end

  test "if the date is today, uses now", %{conn: conn} do
    now = Util.now

    conn = conn
    |> assign(:date, now |> Timex.to_date)
    |> DateTime.call([])

    assert Timex.between?(
      conn.assigns[:datetime],
      Timex.shift(now, seconds: -1),
      Timex.shift(now, seconds: 1))
  end
end
