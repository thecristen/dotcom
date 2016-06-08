defmodule Site.ScheduleControllerTest do
  use Site.ConnCase

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing schedules"
  end
end
