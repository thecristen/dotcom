defmodule Site.ScheduleV2.BusControllerTest do
  use Site.ConnCase, async: true

  test "Contents of bus schedule template are rendered", %{conn: conn} do
    conn = get(conn, bus_path(conn, :show, "758"))
    response = html_response(conn, 200)
    assert response =~ "Route"
  end
end
