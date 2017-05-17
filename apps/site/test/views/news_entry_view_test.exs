defmodule Site.NewsEntryViewTest do
  use Site.ViewCase, async: true

  describe "show.html" do
    test "does not display recent_news when there are two or fewer news entries", %{conn: conn} do
      news_entry = news_entry_factory()
      news_titles = ["News 1", "News 2"]
      recent_news = Enum.map(news_titles, fn(title) -> news_entry_factory(%{title: title}) end)

      Site.NewsEntryView
      |> render_to_string("show.html", conn: conn, news_entry: news_entry, recent_news: recent_news)
      |> refute_text_visible?("Recent News on the T")
    end

    test "does not display more information when the more_information field is empty", %{conn: conn} do
      news_entry = news_entry_factory(%{more_information: ""})

      Site.NewsEntryView
      |> render_to_string("show.html", conn: conn, news_entry: news_entry, recent_news: [])
      |> refute_text_visible?("More Information")
    end
  end

  describe "recent_news.html" do
    test "includes links to recent news entries", %{conn: conn} do
      recent_news_count = Content.NewsEntry.number_of_recent_news_suggestions()
      recent_news = Enum.map(1..recent_news_count, fn(integer) ->
        news_entry_factory(%{id: integer, title: "News Entry #{integer}"})
      end)

      rendered = render_to_string(
        Site.NewsEntryView,
        "_recent_news.html",
        conn: conn,
        recent_news: recent_news
      )

      Enum.each(recent_news, fn(news_entry) ->
        assert rendered =~ news_entry_path(conn, :show, news_entry.id)
        assert rendered =~ news_entry.title
      end)
    end
  end
end
