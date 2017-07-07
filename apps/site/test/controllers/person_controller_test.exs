defmodule Site.PersonControllerTest do
  use Site.ConnCase, async: true

  describe "GET show" do
    test "shows the person if ID exists", %{conn: conn} do
      conn = get(conn, person_path(conn, :show, "2579"))
      assert html_response(conn, 200) =~ "<h1>Joseph Aiello</h1>"
    end

    test "responsds with a 404 if given an invalid ID", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, person_path(conn, :show, "123")
      end
    end
  end
end
