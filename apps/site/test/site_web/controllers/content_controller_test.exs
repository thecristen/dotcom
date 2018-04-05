defmodule SiteWeb.ContentControllerTest do
  use SiteWeb.ConnCase, async: false

  describe "GET - page" do
    test "renders a basic page when the CMS returns a Content.BasicPage", %{conn: conn} do
      conn = get conn, "/basic_page_no_sidebar"
      rendered = html_response(conn, 200)
      assert rendered =~ "Arts on the T"
    end

    test "given special preview query params, return certain revision of node", %{conn: conn} do
      conn = get conn, "/basic_page_no_sidebar?preview&vid=112&nid=6"
      assert html_response(conn, 200) =~ "Arts on the T 112"
    end

    test "renders a basic page without sidebar", %{conn: conn} do
      conn = get conn, "/basic_page_no_sidebar"
      rendered = html_response(conn, 200)

      assert rendered =~ "The MBTA permits musical performances at a number of subway stations in metro Boston"
      assert rendered =~ ~s(class="page-narrow")
    end

    test "renders a basic page with sidebar", %{conn: conn} do
      conn = get conn, "/basic_page_with_sidebar"
      rendered = html_response(conn, 200)

      assert rendered =~ "Fenway Park"
      refute rendered =~ ~s(class="page-narrow")
    end

    test "renders a landing page with all its paragraphs", %{conn: conn} do
      conn = get conn, "/landing_page_with_all_paragraphs"
      rendered = html_response(conn, 200)

      assert rendered =~ ~s(<h1 class="landing-page-title">Paragraphs Guide</h1>)
      assert rendered =~ ~s(<div class="c-title-card__title c-title-card--link__title">Example Card 1</div>)
    end

    test "renders a person page", %{conn: conn} do
      conn = get conn, "/person"
      assert html_response(conn, 200) =~ "<h1>Joseph Aiello</h1>"
    end

    test "redirects for an unaliased news entry response", %{conn: conn} do
      conn = get conn, "/node/3519"
      assert conn.status == 301
    end

    test "redirects for an unaliased event", %{conn: conn} do
      conn = get conn, "/node/3268"
      assert conn.status == 301
    end

    test "redirects for an unaliased project page", %{conn: conn} do
      conn = get conn, "/node/3004"
      assert conn.status == 301
    end

    test "redirects for an unaliased project update", %{conn: conn} do
      conn = get conn, "/node/3005"
      assert conn.status == 301
    end

    test "returns a 404 when alias does not match expected pattern", %{conn: conn} do
      ExUnit.CaptureLog.capture_log(fn ->
        conn = get conn, "/porjects/project-name"
        assert conn.status == 404
      end)
    end

    test "redirects when content type is a redirect", %{conn: conn} do
      conn = get conn, "/redirect_node"
      assert html_response(conn, 302) =~ "www.google.com"
    end

    test "redirects when content type is a redirect and has a query param", %{conn: conn} do
      conn = get conn, "/redirect_node_with_query?id=5"
      assert html_response(conn, 302) =~ "google.com"
    end

    test "retains params (except _format) and redirects when CMS returns a native redirect", %{conn: conn} do
      conn = get conn, "/redirected-url?preview&vid=latest"
      assert conn.status == 302
      assert Plug.Conn.get_resp_header(conn, "location") == ["/different-url?preview=&vid=latest"]
    end

    test "redirects to the old site when no CMS content and certain path", %{conn: conn} do
      conn = get conn, "/fares_and_passes/non-existent?foo=5"
      assert html_response(conn, 302) =~ "/redirect/fares_and_passes/non-existent?foo=5"
    end

    test "renders a 404 when the CMS does not return any content", %{conn: conn} do
      conn = get conn, "/unknown-path-for-content"
      assert html_response(conn, 404)
    end
  end
end
