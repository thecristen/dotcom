defmodule Content.WhatsHappeningItemTest do
  use ExUnit.Case, async: true

  setup do
    [api_item | _] = Content.CMS.Static.whats_happening_response
    %{api_item: api_item}
  end

  test "parses an api response into a Content.WhatsHappeningItem", %{api_item: api_item} do
    assert %Content.WhatsHappeningItem{
      blurb: blurb,
      url: url,
      thumb: %Content.Field.Image{},
      thumb_2x: nil,
    } = Content.WhatsHappeningItem.from_api(api_item)

    assert blurb =~ "The Fiscal and Management Control Board"
    assert url =~ "/about_the_mbta/news_events"
  end
end
