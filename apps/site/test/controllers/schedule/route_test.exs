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
    assert response =~ ~R(Currently, there are no scheduled trips\s+on January 1, 1900.)
  end

  test "returns a friendly message if there are no trips from a given origin on the day", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "Red", origin: "place-alfcl", date: "1970-01-01")
    response = html_response(conn, 200)
    assert response =~ ~R(Currently, there are no scheduled trips\s+from Alewife\s+on January 1, 1970.)
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

  test "@from has the nice name of a station", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "Red", direction_id: 1)
    refute conn.assigns.from.name =~ "Inbound"
  end

  test "shows station info link if a station page exists", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "28")
    response = html_response(conn, 200)
    assert response =~ "View stop info"
  end

  test "returns 404 if a nonexistent route is given", %{conn: conn} do
    conn = get conn, schedule_path(conn, :show, "Teal")
    response = html_response(conn, 404)
    assert response =~ "This page is no longer in service"
  end
end
