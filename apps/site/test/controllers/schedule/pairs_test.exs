defmodule Site.ScheduleController.PairsTest do
  use Site.ConnCase, async: true

  test "origin/destination pairs returns Depature/Arrival times", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, origin: "Anderson/ Woburn", dest: "North Station", direction_id: "1")
    response = html_response(conn, 200)
    assert response =~ "Departure"
    assert response =~ "Arrival"
    assert response =~ "Inbound to: North Station"
  end
end
