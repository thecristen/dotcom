defmodule Content.WhatsHappeningItemTest do
  use ExUnit.Case, async: true

  setup do
    api_items = Content.CMS.Static.whats_happening_response()
    %{api_items: api_items}
  end

  test "parses an api response into a Content.WhatsHappeningItem", %{api_items: api_items} do
    assert %Content.WhatsHappeningItem{
      blurb: blurb,
      link: %Content.Field.Link{url: url},
      thumb: %Content.Field.Image{},
      thumb_2x: %Content.Field.Image{},
    } = Content.WhatsHappeningItem.from_api(Enum.at(api_items, 0))

    assert blurb =~ "Bus shuttles replace Commuter Rail service on the Franklin Line"
    assert url == "/franklin"
  end

  test "it prefers field_image media image values, if present", %{api_items: api_items} do
    assert %Content.WhatsHappeningItem{
      thumb: %Content.Field.Image{
        alt: thumb_alt,
        url: thumb_url
      },
      thumb_2x: nil
    } = Content.WhatsHappeningItem.from_api(Enum.at(api_items, 1))

    assert thumb_alt == "New, media-based image"
    assert thumb_url =~ "sites/default/files/media-image.jpg"
  end

  test "strips out the internal: that drupal adds to relative links", %{api_items: api_items} do
    api_item = Enum.at(api_items, 0)
    api_item = %{api_item | "field_wh_link" => [%{"uri" => "internal:/news/winter", "title" => "", "options" => []}]}

    assert %Content.WhatsHappeningItem{
      link: %Content.Field.Link{url: "/news/winter"}
    } = Content.WhatsHappeningItem.from_api(api_item)
  end
end
