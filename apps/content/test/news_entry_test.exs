defmodule Content.NewsEntryTest do
  use ExUnit.Case

  setup do
    %{api_page: Content.CMS.Static.news_response() |> List.first}
  end

  describe "from_api/1" do
    test "parses api response", %{api_page: api_page} do
      assert %Content.NewsEntry{
        id: id,
        title: title,
        body: body,
        media_contact: media_contact,
        media_email: media_email,
        media_phone: media_phone,
        more_information: more_information,
        posted_on: posted_on,
        teaser: teaser,
        migration_id: migration_id
      } = Content.NewsEntry.from_api(api_page)

      assert id == 1
      assert title == "Example News Entry"
      assert Phoenix.HTML.safe_to_string(body) =~ "<p>BOSTON -- The MBTA"
      assert media_contact == "MassDOT Press Office"
      assert media_email == "media@example.com"
      assert media_phone == "857-368-8500"
      assert Phoenix.HTML.safe_to_string(more_information) =~ "For more information"
      assert posted_on == ~D[2017-01-01]
      assert teaser == "Example teaser"
      assert migration_id == "1234"
    end
  end
end
