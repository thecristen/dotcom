defmodule Content.ImportantNoticeTest do
  use ExUnit.Case, async: true

  setup do
    api_notices = Content.CMS.Static.important_notices_response()
    %{api_notices: api_notices}
  end

  test "it parses the API response into a Content.ImportantNotice struct", %{api_notices: api_notices} do
    assert %Content.ImportantNotice{
      blurb: blurb,
      link: %Content.Field.Link{url: url},
      thumb: %Content.Field.Image{}
    } = Content.ImportantNotice.from_api(Enum.at(api_notices, 0))

    assert blurb == "Watch a live stream of today's FMCB meeting at 12PM."
    assert url == "/events/2018-04-02/fiscal-management-control-board-meeting"
  end

  test "it prefers field_image media image values, if present", %{api_notices: api_notices} do
    assert %Content.ImportantNotice{
      thumb: %Content.Field.Image{
        alt: thumb_alt,
        url: thumb_url
      }
    } = Content.ImportantNotice.from_api(Enum.at(api_notices, 1))

    assert thumb_alt == "New, media-based image"
    assert thumb_url =~ "sites/default/files/media-image.jpg"
  end
end
