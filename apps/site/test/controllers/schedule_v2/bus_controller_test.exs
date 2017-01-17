defmodule Site.ScheduleV2.BusControllerTest do
  use Site.ConnCase, async: true

  test "Contents of bus schedule template are rendered", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "1"))
    response = html_response(conn, 200)
    assert response =~ "To view schedules for a specific"
  end

  test "does not show a trip list until origin has been selected", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "1", direction_id: "1"))
    response = html_response(conn, 200)
    refute response =~ "Scheduled"
  end

  test "shows a trip list when origin has been selected", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "1", origin: "2167"))
    response = html_response(conn, 200)
    assert response =~ "Scheduled"
  end

  test "renders a trip list with origin and destination", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "71", origin: "8178", dest: "2065"))
    response = html_response(conn, 200)
    assert response =~ "Departure"
    assert response =~ "Arrival"
  end

  test "destination selector appears when origin is selected", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "71", origin: "8178"))
    response = html_response(conn, 200)
    assert response =~ "Arriving at:"
  end

  test "destination selector is not visible when no origin has been selected", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "60"))
    response = html_response(conn, 200)
    refute response =~ "Arriving at:"
  end
end
