defmodule Site.ScheduleControllerTest do
  use Site.ConnCase, async: true

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell")
    response = html_response(conn, 200)
    assert response =~ "Lowell Line"
    assert response =~ "North Station"
  end

  test "inbound Lowell schedule contains the trip from Anderson/Woburn", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell", all: "all", direction_id: 1)
    response = html_response(conn, 200)
    assert response =~ "from Anderson/ Woburn"
  end

  test "@from is set to the nice name of a station", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "Red", direction_id: 1)
    response = html_response(conn, 200)
    refute response =~ "Ashmont - Inbound"
  end
end
