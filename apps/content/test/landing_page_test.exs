defmodule Content.LandingPageTest do
  use ExUnit.Case, async: true

  describe "from_api/1" do
    test "it parses the api response" do
      api_page = Content.CMS.Static.landing_page_response()

      assert %Content.LandingPage{
        id: 2564,
        title: title,
        subtitle: subtitle,
        hero_desktop: %Content.Field.Image{},
        hero_mobile: %Content.Field.Image{},
        hero_mobile_2x: %Content.Field.Image{},
      } = Content.LandingPage.from_api(api_page)

      assert title == "Denali National Park"
      assert subtitle == "The greatest park in the world"
    end
  end
end
