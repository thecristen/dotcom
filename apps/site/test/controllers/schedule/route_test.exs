defmodule Site.ScheduleControllerTest do
  use Site.ConnCase, async: true

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell")
    response = html_response(conn, 200)
    assert response =~ "Lowell Line"
    assert response =~ "North Station"
  end

  test "returns a friendly message if there are no trips on the day" do
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

  test "links to the origin station name if one exists", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "Red", origin: "place-alfcl")
    response = html_response(conn, 200)
    assert response =~ ~s(<a href="#{station_path(conn, :show, "place-alfcl")}">Alewife</a>)
  end

  test "does not try to link to a stop if there's no corresponding station page", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "33")
    response = html_response(conn, 200)
    stop_name = "River St @ Milton St"
    assert response =~ stop_name
    refute response =~ ~s(<a href="#{station_path(conn, :show, "33")}">#{stop_name}</a>)
  end

  test "returns 404 if a nonexistent route is given", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "Teal")
    response = html_response(conn, 404)
    assert response =~ "doesn't exist"
  end
end
