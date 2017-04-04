defmodule Content.ImportantNoticeTest do
  use ExUnit.Case, async: true

  setup do
    [api_notice | _] = Content.CMS.Static.important_notices_response()
    %{api_notice: api_notice}
  end

  test "it parses the API response into a Content.ImportantNotice struct", %{api_notice: api_notice} do
    assert %Content.ImportantNotice{
      blurb: blurb,
      url: url,
      thumb: %Content.Field.Image{}
    } = Content.ImportantNotice.from_api(api_notice)

    assert blurb =~ "The Red Line north passageway at Downtown Crossing"
    assert url == "http://www.mbta.com/about_the_mbta/news_events/"
  end
end
