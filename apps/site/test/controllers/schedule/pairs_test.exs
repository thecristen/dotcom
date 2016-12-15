defmodule Site.ScheduleController.PairsTest do
  use Site.ConnCase, async: true

  test "origin/destination pairs returns Departure/Arrival times", %{conn: conn} do
    conn = get conn, schedule_path(
      conn,
      :show, "CR-Lowell",
      origin: "Anderson/ Woburn",
      dest: "North Station",
      direction_id: "1"
    )
    response = html_response(conn, 200)
    assert response =~ "Departure"
    assert response =~ "Arrival"
    assert HtmlSanitizeEx.strip_tags(response) =~ ~R(Inbound\s+to:\s+North Station)
  end

  test "links to origin and destination station pages", %{conn: conn} do
    conn = get conn, schedule_path(
      conn,
      :show, "Red",
      origin: "place-alfcl",
      dest: "place-harsq",
      direction_id: "0"
    )
    response = html_response(conn, 200)
    # NB: if you change the stop selector, make sure this is changed as well
    assert response =~ ~R(<option\s+value="place-alfcl"\s+selected)
    assert response =~ ~R(<option\s+value="place-harsq"\s+selected)
  end

  test "handles a missing direction ID", %{conn: conn} do
    response = conn
    |> get(schedule_path(conn, :show, "Red", origin: "place-alfcl", dest: "place-knncl"))
    |> html_response(200)

    assert response =~ ~s(Southbound)
  end

  test "picks stops based on the calculated direction ID", %{conn: conn} do
    conn = conn
    |> get(schedule_path(conn, :show, "86", origin: "2546", dest: "22549", direction_id: "0"))

    assert hd(conn.assigns.all_stops).id == "place-sull"
  end

  test "handles an empty schedule with origin/destination selected", %{conn: conn} do
    conn = get conn, schedule_path(
      conn,
      :show, "Red",
      origin: "place-alfcl",
      dest: "place-harsq",
      direction_id: "0",
      date: "1970-01-01"
    )
    response = html_response(conn, 200)
    assert response =~ ~R(Currently, there are no scheduled trips\s+from Alewife\s+to Harvard\s+on January 1, 1970.)
  end
end
