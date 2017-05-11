defmodule Site.NewsEntryControllerTest do
  use Site.ConnCase, async: true

  describe "GET show" do
    test "renders a news entry", %{conn: conn} do
      news_entry = news_entry_factory()

      conn = get conn, news_entry_path(conn, :show, news_entry.id)

      body = html_response(conn, 200)
      assert body =~ news_entry.title
      assert body =~ Phoenix.HTML.safe_to_string(news_entry.body)
      assert body =~ Phoenix.HTML.safe_to_string(news_entry.more_information)
    end

    test "includes a recent_news section", %{conn: conn} do
      news_entry = news_entry_factory()

      conn = get conn, news_entry_path(conn, :show, news_entry.id)

      body = html_response(conn, 200)
      assert body =~ "Recent News on the T"
      assert body =~ news_entry.title
      assert body =~ "MBTA Urges Customers to Stay Connected This Winter"
      assert body =~ "FMCB approves Blue Hill Avenue Station on the Fairmount Line"
    end

    test "raises a 404, given an invalid id", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, news_entry_path(conn, :show, "invalid")
      end
    end
  end
end
