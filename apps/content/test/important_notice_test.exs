defmodule Content.ImportantNoticeTest do
  use ExUnit.Case, async: true

  setup do
    [api_notice] = Content.CMS.Static.important_notices_response()
    %{api_notice: api_notice}
  end

  test "it parses the API response into a Content.ImportantNotice struct", %{api_notice: api_notice} do
    assert %Content.ImportantNotice{
      blurb: blurb,
      link: %Content.Field.Link{url: url},
      thumb: %Content.Field.Image{}
    } = Content.ImportantNotice.from_api(api_notice)

    assert blurb == "Watch a live stream of today's FMCB meeting at 12PM."
    assert url == "/events/2018-04-02/fiscal-management-control-board-meeting"
  end
end
