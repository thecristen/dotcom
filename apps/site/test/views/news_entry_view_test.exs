defmodule Site.NewsEntryViewTest do
  use Site.ViewCase, async: true

  describe "index.html" do
    test "does not display a Next link when additional content is not available", %{conn: conn} do
      news_entry = news_entry_factory()

      body =
        Site.NewsEntryView
        |> render_to_string(
          "index.html",
          conn: conn,
          page: 1,
          news_entries: [news_entry],
          upcoming_news_entries: []
        )

      refute_text_visible?(body, "Next")
      refute body =~ news_entry_path(conn, :index, page: 2)
   end

    test "does not display a Previous link on the first page", %{conn: conn} do
      news_entry = news_entry_factory()

      body =
        Site.NewsEntryView
        |> render_to_string(
          "index.html",
          conn: conn,
          page: 1,
          news_entries: [news_entry],
          upcoming_news_entries: []
        )

      refute_text_visible?(body, "Previous")
      refute body =~ news_entry_path(conn, :index, page: 0)
    end
  end

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

    test "does not display Media Contact Information if none given", %{conn: conn} do
      news_entry = news_entry_factory(%{media_contact: nil, media_email: nil, media_phone: nil})

      Site.NewsEntryView
      |> render_to_string("show.html", conn: conn, news_entry: news_entry, recent_news: [])
      |> refute_text_visible?("Media Contact Information")
    end

    test "displays Media Contact Information when present", %{conn: conn} do
      news_entry = news_entry_factory(%{
        media_contact: "Capy",
        media_email: "capy@example.com",
        media_phone: "424-242-4242"
      })

      rendered = render_to_string(Site.NewsEntryView, "show.html", conn: conn, news_entry: news_entry, recent_news: [])

      assert rendered =~ "Media Contact Information"
      assert rendered =~ "contact Capy."
      assert rendered =~ ~s(<a href="mailto:capy@example.com">capy@example.com</a>)
      assert rendered =~ ~s(<a href="tel:1-424-242-4242">424-242-4242</a>)
    end

    test "displays partial information if only some present", %{conn: conn} do
      news_entry = news_entry_factory(%{
        media_contact: nil,
        media_email: nil,
        media_phone: "424-242-4242"
      })

      rendered = render_to_string(Site.NewsEntryView, "show.html", conn: conn, news_entry: news_entry, recent_news: [])

      refute rendered =~ "please contact"
      assert rendered =~ "Phone:"
      refute rendered =~ "Email:"
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
