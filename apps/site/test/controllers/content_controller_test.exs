defmodule Site.ContentControllerTest do
  use Site.ConnCase, async: true

  describe "GET - page" do
    test "renders a basic page when the CMS returns a Content.BasicPage", %{conn: conn} do
      conn = get conn, "/accessibility"
      rendered = html_response(conn, 200)
      assert rendered =~ "Accessibility at the T"
    end

    test "renders a basic page", %{conn: conn} do
      conn = get conn, "/accessibility"
      rendered = html_response(conn, 200)

      assert rendered =~ "the MBTA is dedicated to providing excellent service to customers of all abilities"
    end

    test "renders a landing page with all its paragraphs", %{conn: conn} do
      conn = get conn, "/cms/style-guide"
      rendered = html_response(conn, 200)

      assert rendered =~ ~s(<h1 class="landing-page-title">Paragraphs Guide</h1>)
      assert rendered =~ ~s(<div class="title-card-title">Example Card 1</div>)
    end

    test "renders a project update when the CMS returns a Content.ProjectUpdate", %{conn: conn} do
      conn = get conn, "/gov-center-project"
      assert html_response(conn, 200) =~ "Government Center Construction"
    end

    test "renders a 404 when the CMS does not return any content", %{conn: conn} do
      conn = get conn, "/unknown-path-for-content"
      assert html_response(conn, 404)
    end
  end
end
