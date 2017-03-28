defmodule Content.NewsEntryTest do
  use ExUnit.Case

  import Content.CMSTestHelpers, only: [update_api_response: 3]

  setup do
    %{api_page: Content.CMS.Static.recent_news_response |> List.first}
  end

  describe "from_api/1" do
    test "parses api response", %{api_page: api_page} do
      assert %Content.NewsEntry{
        id: id,
        title: title,
        body: {:safe, body},
        featured_image: %Content.Field.Image{},
        media_contact_name: media_contact_name,
        media_contact_info: media_contact_info,
        more_information: {:safe, more_information},
        updated_at: updated_at
      } = Content.NewsEntry.from_api(api_page)

      assert id == "18"
      assert title == "FMCB approves Blue Hill Avenue Station on the Fairmount Line"
      assert body =~ "<p>BOSTON -- The MBTA"
      assert media_contact_name == "MassDOT Press Office"
      assert media_contact_info == "857-368-8500"
      assert more_information == ""
      assert DateTime.to_unix(updated_at) == 1488904773
    end
  end
end
