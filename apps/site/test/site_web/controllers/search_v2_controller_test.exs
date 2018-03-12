defmodule SiteWeb.SearchV2ControllerTest do
  use SiteWeb.ConnCase, async: true
  describe "index" do
    test "renders search results page if flag is enabled", %{conn: conn} do
      conn = put_req_cookie(conn, "search_v2", "true")
      conn = get conn, search_v2_path(conn, :index)
      assert html_response(conn, 200) =~ "Search by keyword"
    end

    test "404 if flag is disabled", %{conn: conn} do
      conn = put_req_cookie(conn, "search_v2", "false")
      conn = get conn, search_v2_path(conn, :index)
      assert conn.status == 404
    end
  end
end
