defmodule ContentControllerTest do
  use Site.ConnCase, async: true

  describe "GET - page" do
    test "renders a basic page when the CMS returns a Content.BasicPage", %{conn: conn} do
      conn = get conn, "/accessibility"
      assert html_response(conn, 200) =~ "Accessibility at the T"
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
