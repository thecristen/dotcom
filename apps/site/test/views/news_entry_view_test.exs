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
end
