defmodule Site.ScheduleV2.CommuterRailControllerTest do
  use Site.ConnCase, async: true

  test "renders schedule information for a line", %{conn: conn} do
    response = conn
    |> get(commuter_rail_path(conn, :timetable, "CR-Lowell"))
    |> html_response(200)

    assert response =~ "Lowell"
    assert response =~ "Anderson/Woburn"
  end
end
