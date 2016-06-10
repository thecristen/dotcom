defmodule Site.ScheduleControllerTest do
  use Site.ConnCase

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell")
    response = html_response(conn, 200)
    assert response =~ "Lowell Line"
    assert response =~ "North Station"
  end
end
