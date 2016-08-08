defmodule Site.ScheduleControllerTest do
  use Site.ConnCase, async: true

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell")
    response = html_response(conn, 200)
    assert response =~ "Lowell Line"
    assert response =~ "North Station"
  end

  test "returns a friendly message if there are no trips on the day", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell", date: "1900-01-01")
    response = html_response(conn, 200)
    assert response =~ "Lowell Line"
    assert response =~ "There are no currently scheduled trips on January 1, 1900."
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

  test "returns 404 if a nonexistent route is given", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "Teal")
    response = html_response(conn, 404)
    assert response =~ "the page you're looking for has been derailed and cannot be found."
  end
end
