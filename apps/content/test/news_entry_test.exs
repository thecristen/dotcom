defmodule Content.NewsEntryTest do
  use ExUnit.Case

  setup do
    %{api_page_no_path_alias: Content.CMS.Static.news_response() |> Enum.at(0),
      api_page_path_alias: Content.CMS.Static.news_response() |> Enum.at(1)}
  end

  describe "from_api/1" do
    test "parses api response without path alias", %{api_page_no_path_alias: api_page} do
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
        migration_id: migration_id,
        path_alias: path_alias
      } = Content.NewsEntry.from_api(api_page)

      assert id == 1
      assert Phoenix.HTML.safe_to_string(title) == "Example News Entry"
      assert Phoenix.HTML.safe_to_string(body) =~ "<p>BOSTON -- The MBTA"
      assert media_contact == "MassDOT Press Office"
      assert media_email == "media@example.com"
      assert media_phone == "857-368-8500"
      assert Phoenix.HTML.safe_to_string(more_information) =~ "For more information"
      assert posted_on == ~D[2017-01-01]
      assert Phoenix.HTML.safe_to_string(teaser) == "Example teaser"
      assert migration_id == "1234"
      assert path_alias == "1"
    end

    test "parses api response with path alias", %{api_page_path_alias: api_page} do
      assert %Content.NewsEntry{
        path_alias: path_alias
      } = Content.NewsEntry.from_api(api_page)

      assert path_alias == "path_to/alias_path"
    end
  end
end
