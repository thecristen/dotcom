defmodule Content.MenuLinksTest do
  use ExUnit.Case, async: true

  import Content.MenuLinks

  setup do
    api_data =
      Content.CMS.Static.basic_page_with_sidebar_response()
      |> Map.get("field_sidebar_menu")
      |> List.first

    %{api_data: api_data}
  end

  describe "from_api/1" do
    test "parses the data into a MenuLinks struct", %{api_data: api_data} do
      assert %Content.MenuLinks{
        title: "Parking",
        links: [
          %Content.Field.Link{
            title: "Parking Info By Station",
            url: "/parking/by-station"
          },
          %Content.Field.Link{},
          %Content.Field.Link{},
          %Content.Field.Link{
            title: "Contact",
            url: "https://google.com"
          },
        ]
      } = from_api(api_data)
    end
  end
end
