defmodule Site.ScheduleControllerTest do
  use Site.ConnCase, async: true

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "CR-Lowell")
    response = html_response(conn, 200)
    assert response =~ "Lowell Line"
    assert response =~ "North Station"
  end

  test "returns a friendly message if there are no trips on the day", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "CR-Lowell", date: "1900-01-01")
    response = html_response(conn, 200)
    assert response =~ "Lowell"
    assert response =~ ~R(There are no currently scheduled trips\s+on January 1, 1900.)
  end

  test "returns a friendly message if there are no trips from a given origin on the day", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "Red", origin: "place-alfcl", date: "1970-01-01")
    response = html_response(conn, 200)
    assert response =~ ~R(There are no currently scheduled trips\s+from Alewife\s+on January 1, 1970.)
  end

  test "inbound Lowell schedule contains the trip from Anderson/Woburn", %{conn: conn} do
    next_weekday = "America/New_York"
    |> Timex.now()
    |> Timex.end_of_week(:mon)
    |> Timex.shift(days: 3)
    |> Timex.format!("{ISOdate}")

    conn = get conn, schedule_path(
      conn, :show,
      "CR-Lowell", all: "all", direction_id: 1, date: next_weekday)
    response = html_response(conn, 200)
    assert response =~ "from Anderson/Woburn"
  end

  test "@from is set to the nice name of a station", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "Red", direction_id: 1)
    response = html_response(conn, 200)
    refute response =~ "Ashmont - Inbound"
  end

  test "shows station info link if a station page exists", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "28")
    response = html_response(conn, 200)
    assert response =~ "view station info"
  end

  test "does not show station info link if no station page exists", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "71")
    response = html_response(conn, 200)
    refute response =~ "view station info"
  end

  test "returns 404 if a nonexistent route is given", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "Teal")
    response = html_response(conn, 404)
    assert response =~ "the page you're looking for has been derailed and cannot be found."
  end
end
