defmodule Site.NewsEntryViewTest do
  use Site.ViewCase, async: true

  describe "news_entry.html" do
    test "does not display more information when the more_information field is empty", %{conn: conn} do
      page = %{build_page_content() | more_information: ""}

      metadata = %{ recent_news: [] }

      Site.ContentView
      |> render_to_string("news_entry.html", conn: conn, page: page, metadata: metadata)
      |> refute_text_visible?("More Information")

    end

    test "does not display recent news when recent_news is empty", %{conn: conn} do
      page = build_page_content()
      metadata = %{ recent_news: [] }

      Site.ContentView
      |> render_to_string("news_entry.html", conn: conn, page: page, metadata: metadata)
      |> refute_text_visible?("Recent News on the T")
    end

    def refute_text_visible?(html, text) do
      refute html =~ text
    end

    def build_page_content do
      %Content.NewsEntry{
        body: Phoenix.HTML.raw("Stay safe this winter"),
        title: "News Title",
        updated_at: DateTime.utc_now,
        more_information: "Visit us for more information",
        featured_image: %Content.Field.Image{
          alt: "alt",
          url: "image_url"
        }
      }
    end
  end
end
