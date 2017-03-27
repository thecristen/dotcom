defmodule ContentControllerTest do
  use Site.ConnCase

  describe "GET - page" do
    test "renders a news entry when the CMS returns a Content.NewsEntry", %{conn: conn} do
      conn = get conn, "/news/winter"
      assert html_response(conn, 200) =~ "FMCB approves Blue Hill Avenue Station"
    end

    test "renders a 404 when the CMS does not return any content", %{conn: conn} do
      conn = get conn, "/unknown-path-for-content"
      assert html_response(conn, 404)
    end
  end
end
