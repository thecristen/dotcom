defmodule Content.BasicPageTest do
  use ExUnit.Case, async: true

  alias Content.BasicPage
  alias Content.Paragraph.CustomHTML
  alias Phoenix.HTML

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

      assert id == 3195
      assert Phoenix.HTML.safe_to_string(body) =~ "<p>The MBTA permits musical performances"
      assert title == "Arts on the T"
    end

    test "it strips out script tags", %{api_page: api_page} do
      api_page = update_api_response(api_page, "body", "<script>alert()</script> <p>Hi</p>")

      assert %Content.BasicPage{body: body} = Content.BasicPage.from_api(api_page)
      assert Phoenix.HTML.safe_to_string(body) == "alert() <p>Hi</p>"
    end

    test "it parses a sidebar menu" do
      api_page = Content.CMS.Static.basic_page_with_sidebar_response()

      assert %Content.BasicPage{
               sidebar_menu: %Content.MenuLinks{
                 blurb:
                   {:safe,
                    "<p>Visiting Boston? Learn more about some of the popular spots you can get to on the T.</p>"}
               }
             } = Content.BasicPage.from_api(api_page)
    end
  end

  describe "has_right_rail?/1" do
    test "returns true if any paragraphs are for the right rail" do
      page = %BasicPage{
        paragraphs: [
          %CustomHTML{body: HTML.raw("<p>Hello</p>"), right_rail: false},
          %CustomHTML{body: HTML.raw("<p>world</p>"), right_rail: true}
        ]
      }

      assert BasicPage.has_right_rail?(page)
    end

    test "returns false if no paragraphs are for the right rail" do
      page = %BasicPage{
        paragraphs: [
          %CustomHTML{body: HTML.raw("<p>Hello</p>"), right_rail: false},
          %CustomHTML{body: HTML.raw("<p>world</p>"), right_rail: false}
        ]
      }

      refute BasicPage.has_right_rail?(page)
    end
  end
end
