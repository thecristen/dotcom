defmodule Site.PageViewTest do
  use Site.ConnCase, async: true

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

      assert rendered == ~s(<img alt="This is an image" src="/foo_1" srcset="/foo_1, /foo_2 2x">)
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
end
