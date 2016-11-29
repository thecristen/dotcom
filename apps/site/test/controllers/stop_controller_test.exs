defmodule Site.StopControllerTest do
  use Site.ConnCase, async: true

  test "redirects to subway stops on index", %{conn: conn} do
    conn = get conn, stop_path(conn, :index)
    assert redirected_to(conn) == stop_path(conn, :show, :subway)
  end

  test "shows stations by mode", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, :subway)
    response = html_response(conn, 200)
    for line <- ["Green", "Red", "Blue", "Orange", "Mattapan"] do
      assert response =~ line
    end
  end

  test "shows stations", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "place-portr")
    assert html_response(conn, 200) =~ "Porter Square"
    assert conn.assigns.breadcrumbs == [
      {stop_path(conn, :index), "Stations"},
      "Porter Square"
    ]
  end

  test "shows stops", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "22")
    assert html_response(conn, 200) =~ "E Broadway @ H St"
    assert conn.assigns.breadcrumbs == [
      "E Broadway @ H St"
    ]
  end

  test "can show stations with spaces", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "Anderson/ Woburn")
    assert html_response(conn, 200) =~ "Anderson/Woburn"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, stop_path(conn, :show, -1)
    end
  end
end
