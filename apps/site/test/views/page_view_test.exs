defmodule Site.PageViewTest do
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
      |> Site.PageView.whats_happening_image
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
      |> Site.PageView.whats_happening_image
      |> Phoenix.HTML.safe_to_string

      assert rendered == ~s(<img alt="This is an image" src="/foo_1">)
    end
  end

  describe "important notices" do
    test "renders _important_notice.html" do
      notice = %Content.ImportantNotice{
        blurb: "Uh oh, this is very important!",
        url: "http://example.com/important",
        thumb: %Content.Field.Image{}
      }
      rendered = render_to_string(Site.PageView, "_important_notice.html", important_notice: notice)
      assert rendered =~ "Uh oh, this is very important!"
    end
  end
end
