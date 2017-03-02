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

  describe "photo credits" do
    test "are included on homepage footer", %{conn: conn} do
      footer_text =
        conn
        |> get(page_path(conn, :index))
        |> html_response(200)
        |> Floki.find("footer")
        |> Floki.text()
        |> String.replace("\n", " ")
      assert footer_text =~ "Zakim bridge and the TD Garden photo by: Robbie Shade"
      assert footer_text =~ "Sunset at BU Central photo by: Mark Zastrow"
    end

    test "are not included in footer when not on the homepage", %{conn: conn} do
      footer_text =
        conn
        |> get(mode_path(conn, :ferry))
        |> html_response(200)
        |> Floki.find("footer")
        |> Floki.text()
        |> String.replace("\n", " ")
      refute footer_text =~ "Zakim bridge and the TD Garden photo by: Robbie Shade"
      refute footer_text =~ "Sunset at BU Central photo by: Mark Zastrow"
    end
  end
end
