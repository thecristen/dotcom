defmodule Site.ScheduleV2.SubwayControllerTest do
  use Site.ConnCase, async: true

  test "Renders frequency of transit on a line", %{conn: conn} do
    conn = get(conn, subway_path(conn, :frequency, "11"))
    response = html_response(conn, 200)
    assert response =~ "Schedules For Today"
  end
end
