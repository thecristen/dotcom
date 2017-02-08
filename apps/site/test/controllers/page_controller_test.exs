defmodule Site.PageControllerTest do
  use Site.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Massachusetts Bay Transportation Authority"
    assert response_content_type(conn, :html) =~ "charset=utf-8"
  end

  test "assigns post_container_template", %{conn: conn} do
    conn = get conn, "/"
    assert conn.assigns.post_container_template == "_post_container.html"
  end

  describe "What's happening banner" do
    test "shown when flag is in URL", %{conn: conn} do
      conn = get(conn, "/?whats_happening_banner")
      assert html_response(conn, 200) =~ "important-whats-happening"
    end

    test "hidden when flag is not in URL", %{conn: conn} do
      conn = get(conn, "/")
      refute html_response(conn, 200) =~ "important-whats-happening"
    end
  end
end
