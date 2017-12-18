defmodule SiteWeb.ContentControllerTest do
  use SiteWeb.ConnCase, async: false

  describe "GET - page" do
    test "renders a basic page when the CMS returns a Content.BasicPage", %{conn: conn} do
      conn = get conn, "/accessibility"
      rendered = html_response(conn, 200)
      assert rendered =~ "Accessibility at the T"
    end

    test "renders a basic page without sidebar", %{conn: conn} do
      conn = get conn, "/accessibility"
      rendered = html_response(conn, 200)

      assert rendered =~ "the MBTA is dedicated to providing excellent service to customers of all abilities"
      assert rendered =~ ~s(class="page-narrow")
    end

    test "renders a basic page with sidebar", %{conn: conn} do
      conn = get conn, "/parking/by-station"
      rendered = html_response(conn, 200)

      assert rendered =~ "Parking Info by Station"
      refute rendered =~ ~s(class="page-narrow")
    end

    test "renders an event", %{conn: conn} do
      conn = get conn, "/node/17"
      rendered = html_response(conn, 200)
      assert rendered =~ "Audit Committee Meeting"
    end

    test "renders a landing page with all its paragraphs", %{conn: conn} do
      conn = get conn, "/cms/style-guide"
      rendered = html_response(conn, 200)

      assert rendered =~ ~s(<h1 class="landing-page-title">Paragraphs Guide</h1>)
      assert rendered =~ ~s(<div class="c-title-card__title c-title-card--link__title">Example Card 1</div>)
    end

    test "renders a news entry", %{conn: conn} do
      conn = get conn, "/node/1"
      rendered = html_response(conn, 200)
      assert rendered =~ "Example News Entry"
    end

    test "renders a person page", %{conn: conn} do
      conn = get conn, "/people/joseph-aiello"
      assert html_response(conn, 200) =~ "<h1>Joseph Aiello</h1>"
    end

    test "renders a project", %{conn: conn} do
      conn = get conn, "/node/2679"
      rendered = html_response(conn, 200)
      assert rendered =~ "Ruggles Station Platform Project"
    end

    test "renders project update", %{conn: conn} do
      conn = get conn, "/node/123"
      rendered = html_response(conn, 200)
      assert rendered =~ "Project Update Title"
    end

    test "redirects when content type is a redirect", %{conn: conn} do
      conn = get conn, "/test/redirect"
      assert html_response(conn, 302) =~ "www.google.com"
    end

    test "redirects when content type is a redirect and has a query param", %{conn: conn} do
      conn = get conn, "/test/path?id=5"
      assert html_response(conn, 302) =~ "google.com"
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
