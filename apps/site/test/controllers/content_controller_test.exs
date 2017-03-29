defmodule ContentControllerTest do
  use Site.ConnCase

  describe "GET - page" do
    test "renders a news entry when the CMS returns a Content.NewsEntry", %{conn: conn} do
      conn = get conn, "/news/winter"
      assert html_response(conn, 200) =~ "FMCB approves Blue Hill Avenue Station"
    end

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
