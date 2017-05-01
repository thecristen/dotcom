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

  test "homepage does not have .sticky-footer class", %{conn: conn} do
    [body_class] =
      build_conn()
      |> get(page_path(conn, :index))
      |> html_response(200)
      |> Floki.find("body")
      |> Floki.attribute("class")
    assert body_class == "no-js"
  end

  test "non-homepage has sticky-footer class", %{conn: conn} do
    [body_class] =
      build_conn()
      |> get(mode_path(conn, :ferry))
      |> html_response(200)
      |> Floki.find("body")
      |> Floki.attribute("class")
    assert body_class == "no-js sticky-footer"
  end
end
