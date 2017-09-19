defmodule Site.PersonControllerTest do
  use Site.ConnCase, async: true

  describe "GET show" do
    test "shows the person if ID exists", %{conn: conn} do
      conn = get(conn, person_path(conn, :show, "2579"))
      assert html_response(conn, 200) =~ "<h1>Joseph Aiello</h1>"
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, person_path(conn, :show, "123")
      assert conn.status == 404
    end
  end
end
