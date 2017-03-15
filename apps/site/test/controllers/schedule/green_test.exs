defmodule Site.ScheduleController.GreenTest do
  use Site.ConnCase, async: true

  for route <- ["Red", "Blue", "Orange", "Green", "Green-B", "Green-C", "Green-D", "Green-E"] do
    for direction_id <- [0, 1] do
      name = "test_#{route}-#{direction_id} doesn't display 0 minute headway"
      test name, %{conn: conn} do
        conn = get conn, schedule_v1_path(
          conn,
          :show,
          unquote(route),
          all: "all",
          direction_id: unquote(direction_id)
        )
        response = html_response(conn, 200)
        refute response =~ "Every 0-"
      end
    end
  end
end
