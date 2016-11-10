defmodule Content.PageTest do
  use ExUnit.Case, async: true

  describe "rewrite_static_files" do
    test "rewrites static parts of the body to go through our static_url helper" do
      page = %Content.Page{
        title: "",
        updated_at: Timex.now,
        body: """

        <img src="/sites/default/files/converted.jpg">
        <img src="/sites/default/files/also_converted.jpg">
        /sites/default/files/not_converted.jpg
        <img src="/sites/other/files/not_converted.jpg">
        """
      }
      new_page = Content.Page.rewrite_static_files(page)

      assert new_page.body =~ Content.Config.apply(:static, ["/sites/default/files/converted.jpg"])
      assert new_page.body =~ Content.Config.apply(:static, ["/sites/default/files/also_converted.jpg"])
      refute new_page.body =~ Content.Config.apply(:static, ["/sites/default/files/not_converted.jpg"])
      refute new_page.body =~ Content.Config.apply(:static, ["/sites/other/files/not_converted.jpg"])
    end
  end
end
