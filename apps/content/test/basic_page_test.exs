defmodule Content.BasicPageTest do
  use ExUnit.Case, async: true

  import Content.CMSTestHelpers, only: [update_api_response: 3]

  setup do
    %{api_page: Content.CMS.Static.basic_page_response()}
  end

  describe "from_api/1" do
    test "it parses the api response", %{api_page: api_page} do
      assert %Content.BasicPage{
        id: id,
        body: body,
        title: title
      } = Content.BasicPage.from_api(api_page)

      assert id == "6"
      assert Phoenix.HTML.safe_to_string(body) =~ "<p>From accessible buses,"
      assert title == "Accessibility at the T"
    end

    test "it strips out script tags", %{api_page: api_page} do
      api_page = update_api_response(api_page, "body", "<script>alert()</script> <p>Hi</p>")

      assert %Content.BasicPage{body: body} = Content.BasicPage.from_api(api_page)
      assert Phoenix.HTML.safe_to_string(body) == "alert() <p>Hi</p>"
    end
  end
end
