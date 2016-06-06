defmodule Site.PageControllerTest do
  use Site.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Transit Near Me"
  end
end
