defmodule SiteWeb.NewsEntryControllerTest do
  use SiteWeb.ConnCase, async: true
  import Site.PageHelpers, only: [breadcrumbs_include?: 2]

  describe "GET index" do
    test "renders a list of news entries", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :index)

      body = html_response(conn, 200)
      assert body =~ "News"
      assert breadcrumbs_include?(body, "News")
    end

    test "supports pagination", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :index, page: 2)

      body = html_response(conn, 200)
      assert body =~ "Previous"
      assert body =~ news_entry_path(conn, :index, page: 1)
      assert body =~ "Next"
      assert body =~ news_entry_path(conn, :index, page: 3)
    end
  end

  describe "GET show" do
    test "renders a news entry when entry has no path_alias", %{conn: conn} do
      news_entry = news_entry_factory(0, path_alias: nil)

      conn = get conn, news_entry_path(conn, :show, news_entry)

      assert html_response(conn, 200) =~ "Example News Entry"
    end

    test "disambiguation: renders a news entry whose alias pattern is /news/:title instead of /news/:date/:title", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "incorrect-pattern")
      assert html_response(conn, 200) =~ "MBTA Urges Customers to Stay Connected This Winter"
    end

    test "renders a news entry which has a path_alias", %{conn: conn} do
     news_entry = news_entry_factory(1)

     assert news_entry.path_alias == "/news/date/title"

     news_entry_title = Phoenix.HTML.safe_to_string(news_entry.title)
     conn = get conn, news_entry_path(conn, :show, news_entry)

     body = html_response(conn, 200)
     assert body =~ Phoenix.HTML.safe_to_string(news_entry.title)
     assert body =~ Phoenix.HTML.safe_to_string(news_entry.body)
     assert body =~ Phoenix.HTML.safe_to_string(news_entry.more_information)
     assert breadcrumbs_include?(body, ["News", news_entry_title])
   end

    test "renders a preview of the requested news entry", %{conn: conn} do
      news_entry = news_entry_factory(1)
      conn = get(conn, news_entry_path(conn, :show, news_entry) <> "?preview&vid=112")
      assert html_response(conn, 200) =~ "MBTA Urges Customers to Stay Connected This Winter 112"
    end

    test "includes Recent News suggestions", %{conn: conn} do
      news_entry = news_entry_factory(1)

      conn = get conn, news_entry_path(conn, :show, news_entry)

      body = html_response(conn, 200)
      assert body =~ "Recent News on the T"
      assert body =~ "MBTA Urges Customers to Stay Connected This Winter"
      assert body =~ "FMCB approves Blue Hill Avenue Station on the Fairmount Line"
      assert body =~ "MBTA Urges Customers to Stay Connected This Summer"
    end

    test "retains params (except _format) and redirects when CMS returns a native redirect", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "redirected-url") <> "?preview&vid=999"
      assert conn.status == 302
      assert Plug.Conn.get_resp_header(conn, "location") == ["/news/date/title?preview=&vid=999"]
    end

    test "renders a 404 given an valid id but mismatching content type", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "17")
      assert conn.status == 404
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "2018", "invalid-news-entry")
      assert conn.status == 404
    end
  end
end
