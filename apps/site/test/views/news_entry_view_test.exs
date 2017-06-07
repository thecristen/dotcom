defmodule Site.NewsEntryViewTest do
  use Site.ViewCase, async: true
  use Quixir

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

    test "displays appropriate Media Contact Information", %{conn: conn} do
      ptest media_contact: choose(from: [value("Mass DOT"), value(nil)]),
        media_email: choose(from: [value("massdot@example.com"), value(nil)]),
        media_phone: choose(from: [value("555-555-5555"), value(nil)]) do

        news_entry = news_entry_factory(%{
          media_contact: media_contact,
          media_email: media_email,
          media_phone: media_phone
        })

        rendered = render_to_string(Site.NewsEntryView, "show.html", conn: conn, news_entry: news_entry, recent_news: [])

        if is_nil(media_contact) && is_nil(media_email) && is_nil(media_phone) do
          refute rendered =~ "Media Contact Information"
        else
          assert rendered =~ "Media Contact Information"

          if is_nil(media_contact) do
            refute rendered =~ "contact #{media_contact}."
          else
            assert rendered =~ "contact #{media_contact}."
          end

          if is_nil(media_email) do
            refute rendered =~ "Email:"
          else
            assert rendered =~ "Email:"
          end

          if is_nil(media_phone) do
            refute rendered =~ "Phone:"
          else
            assert rendered =~ "Phone:"
          end
        end
      end
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
