defmodule Site.ScheduleController.PairsTest do
  use Site.ConnCase, async: true

  test "origin/destination pairs returns Departure/Arrival times", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, origin: "Anderson/ Woburn", dest: "North Station", direction_id: "1")
    response = html_response(conn, 200)
    assert response =~ "Departure"
    assert response =~ "Arrival"
    assert response =~ ~R(Inbound\s+to: North Station)
  end

  test "links to origin and destination station pages", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, origin: "place-alfcl", dest: "place-harsq", direction_id: "0")
    response = html_response(conn, 200)
    assert response =~ ~s(<a href="#{station_path(conn, :show, "place-alfcl")}">Alewife</a>)
    assert response =~ ~s(<a href="#{station_path(conn, :show, "place-harsq")}">Harvard</a>)
  end
end
