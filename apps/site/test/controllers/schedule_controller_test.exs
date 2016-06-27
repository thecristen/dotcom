defmodule Site.ScheduleControllerTest do
  use Site.ConnCase, async: true

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell")
    response = html_response(conn, 200)
    assert response =~ "Lowell Line"
    assert response =~ "North Station"
  end

  test "inbound Lowell schedule contains the trip from Anderson/Woburn" do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell", all: "all", direction_id: 1)
    response = html_response(conn, 200)
    assert response =~ "from Anderson/ Woburn"
  end

  for route <- ["Red", "Blue", "Orange", "Green-B", "Green-C", "Green-D", "Green-E"] do
    for direction_id <- [0, 1] do
      name = "test_#{route}-#{direction_id} doesn't display 0 minute headway"
      test name do
        conn = get conn, schedule_path(conn, :index, route: unquote(route), all: "all", direction_id: unquote(direction_id))
        response = html_response(conn, 200)
        refute response =~ "Every 0-"
      end
    end
  end
end
