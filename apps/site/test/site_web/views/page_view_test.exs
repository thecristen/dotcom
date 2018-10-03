defmodule SiteWeb.PageViewTest do
  use Site.ViewCase, async: true

  describe "whats_happening_image/1" do
    test "if the item has a 2x version, includes a srcset attribute" do
      rendered = %Content.WhatsHappeningItem{
        thumb: %Content.Field.Image{
          alt: "This is an image",
          url: "/foo_1"
        },
        thumb_2x: %Content.Field.Image{
          alt: "",
          url: "/foo_2"
        }
      }
      |> SiteWeb.PageView.whats_happening_image
      |> Phoenix.HTML.safe_to_string

      assert rendered == ~s(<img alt="This is an image" sizes="\(max-width: 543px\) 100vw, 33vw" src="/foo_1" srcset="/foo_1 304w, /foo_2 608w">)
    end

    test "if the item doesn't have a 2x version, does not include srcset" do
      rendered = %Content.WhatsHappeningItem{
        thumb: %Content.Field.Image{
          alt: "This is an image",
          url: "/foo_1"
        },
        thumb_2x: nil
      }
      |> SiteWeb.PageView.whats_happening_image
      |> Phoenix.HTML.safe_to_string

      assert rendered == ~s(<img alt="This is an image" src="/foo_1">)
    end
  end

  describe "banners" do
    test "renders _banner.html for important banners" do
      banner = %Content.Banner{
        title: "Important Banner Title",
        blurb: "Uh oh, this is very important!",
        link: %Content.Field.Link{url: "http://example.com/important", title: "Call to Action"},
        thumb: %Content.Field.Image{},
        banner_type: :important,
        updated_on: "September 27, 2018"
      }
      rendered = render_to_string(SiteWeb.PageView, "_banner.html", banner: banner)
      assert rendered =~ "Important Banner Title"
      assert rendered =~ "Uh oh, this is very important!"
      assert rendered =~ "Call to Action"
      refute rendered =~ "September 27, 2018"
    end

    test "renders _banner.html for default banners" do
      banner = %Content.Banner{
        title: "Default Banner Title",
        blurb: "This is not as important.",
        link: %Content.Field.Link{url: "http://example.com/default", title: "Call to Action"},
        thumb: %Content.Field.Image{},
        banner_type: :default,
        updated_on: "September 27, 2018"
      }
      rendered = render_to_string(SiteWeb.PageView, "_banner.html", banner: banner)
      assert rendered =~ "Default Banner Title"
      refute rendered =~ "This is not as important."
      refute rendered =~ "Call to Action"
      assert rendered =~ "September 27, 2018"
    end
  end

  describe "shortcut_icons/0" do
    test "renders shortcut icons" do
      rendered = SiteWeb.PageView.shortcut_icons() |> Phoenix.HTML.safe_to_string()
      icons = Floki.find(rendered, ".m-homepage__shortcut")
      assert length(icons) == 6
    end
  end

  describe "render_news_entries/1" do
    test "renders news entries", %{conn: conn} do
      now = Util.now()
      entries = for idx <- 1..7 do
        %Content.NewsEntry{
          title: "News Entry #{idx}",
          posted_on: Timex.shift(now, hours: -idx),
        }
      end
      rendered =
        conn
        |> assign(:news, entries)
        |> SiteWeb.PageView.render_news_entries()
        |> Phoenix.HTML.safe_to_string()
      assert rendered |> Floki.find(".m-news-entry") |> Enum.count() == 7
      assert rendered |> Floki.find(".m-news-entry--large") |> Enum.count() == 3
      assert rendered |> Floki.find(".m-news-entry--small") |> Enum.count() == 4
    end
  end
end
