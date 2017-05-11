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

      recent_news_entries_ids = [news_entry.id, 2, 3]
      assert_recent_news_includes_links_to_news_entries(conn, body, recent_news_entries_ids)
    end

    test "raises a 404, given an invalid id", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, news_entry_path(conn, :show, "invalid")
      end
    end

    defp assert_recent_news_includes_links_to_news_entries(conn, body, ids) do
      Enum.each(ids, fn(id) ->
        assert body =~ news_entry_path(conn, :show, id)
      end)
    end
  end
end
