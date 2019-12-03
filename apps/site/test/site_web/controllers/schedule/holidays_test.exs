defmodule SiteWeb.ScheduleController.HolidaysTest do
  use SiteWeb.ConnCase, async: true

  test "gets results", %{conn: conn} do
    conn =
      conn
      |> assign(:date, ~D[2020-02-28])
      |> SiteWeb.ScheduleController.Holidays.call([])

    assert Enum.count(conn.assigns.holidays) == 16
  end

  test "if there is no date, doesnt assign holidays", %{conn: conn} do
    conn =
      conn
      |> SiteWeb.ScheduleController.Holidays.call([])

    refute conn.assigns[:holidays]
  end
end
