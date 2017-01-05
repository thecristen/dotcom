defmodule Site.ScheduleV2.BusControllerTest do
  use Site.ConnCase, async: true

  test "Contents of bus schedule template are rendered", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "1"))
    response = html_response(conn, 200)
    assert response =~ "To view schedules for a specific"
  end

  test "renders a trip list from its origin", %{conn: conn} do
    conn = get(conn, bus_path(conn, :origin, "1", direction_id: "1"))
    response = html_response(conn, 200)
    assert response =~ "Inbound to"
  end

  test "renders a trip list with origin and destination", %{conn: conn} do
    conn = get(conn, bus_path(conn, :origin_destination, "71", origin: "8178", dest: "2065"))
    response = html_response(conn, 200)
    assert response =~ "Departure"
    assert response =~ "Arrival"
  end
end
