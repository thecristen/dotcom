defmodule Site.StationControllerTest do
  use Site.ConnCase, async: true

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, station_path(conn, :index)
    assert html_response(conn, 200) =~ "Alewife"
  end

  test "shows chosen resource", %{conn: conn} do
    conn = get conn, station_path(conn, :show, "place-portr")
    assert html_response(conn, 200) =~ "Porter Square"
  end

  test "can show stations with spaces", %{conn: conn} do
    conn = get conn, station_path(conn, :show, "Anderson/ Woburn")
    assert html_response(conn, 200) =~ "Anderson/Woburn"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, station_path(conn, :show, -1)
    end
  end
end
