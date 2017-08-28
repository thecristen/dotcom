defmodule Content.PageTest do
  use ExUnit.Case, async: true

  alias Content.CMS.Static

  describe "from_api/1" do
    test "switches on the node type in the json response and returns the proper page struct" do
      assert %Content.BasicPage{} = Content.Page.from_api(Static.basic_page_response())
      assert %Content.LandingPage{} = Content.Page.from_api(Static.landing_page_response())
      assert %Content.Redirect{} = Content.Page.from_api(Static.redirect_response())
    end
  end
end
