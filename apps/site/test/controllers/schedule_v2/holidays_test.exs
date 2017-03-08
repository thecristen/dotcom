defmodule Site.ScheduleV2Controller.HolidaysTest do
  use Site.ConnCase, async: true

  test "gets 3 results", %{conn: conn} do
    conn = conn
    |> assign(:date, ~D[2017-02-28])
    |> Site.ScheduleV2Controller.Holidays.call([])

    assert Enum.count(conn.assigns.holidays) == 3
  end

  test "if there is no date, doesnt assign holidays", %{conn: conn} do
    conn = conn
    |> Site.ScheduleV2Controller.Holidays.call([])

    refute conn.assigns[:holidays]
  end
end
