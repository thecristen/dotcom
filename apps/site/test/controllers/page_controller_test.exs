defmodule Site.PageControllerTest do
  use Site.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Massachusetts Bay Transportation Authority"
    assert response_content_type(conn, :html) =~ "charset=utf-8"
  end

  test "assigns post_container_template", %{conn: conn} do
    conn = get conn, "/"
    assert conn.assigns.post_container_template == "_post_container.html"
  end
end
