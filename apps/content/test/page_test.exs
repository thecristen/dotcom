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

defmodule Content.Page.ImageTest do
  use ExUnit.Case, async: true

  describe "rewrite_url" do
    test "rewrites URLS to go through the static handler" do
      root = "https://test-domain"
      static_path = "/sites/default/files"

      expected = Content.Config.apply(:static, ["#{static_path}/converted.png"])
      actual = Content.Page.Image.rewrite_url(
        "https://test-domain/sites/default/files/converted.png",
        root: root,
        static_path: static_path)
      assert actual == expected
    end

    test "handles domains with a trailing slash" do
      root = "https://test-domain/"
      static_path = "/sites/default/files"

      expected = Content.Config.apply(:static, ["#{static_path}/converted.png"])
      actual = Content.Page.Image.rewrite_url(
        "https://test-domain/sites/default/files/converted.png",
        root: root,
        static_path: static_path)
      assert actual == expected
    end
  end
end

defmodule Content.Page.FileTest do
  use ExUnit.Case, async: true

  describe "rewrite_url" do
    test "uses the image version of rewrite url" do
      root = "https://test-domain"
      static_path = "/sites/default/files"

      expected = Content.Page.Image.rewrite_url(
        "https://test-domain/sites/default/files/converted.png",
        root: root,
        static_path: static_path)

      actual = Content.Page.File.rewrite_url(
        "https://test-domain/sites/default/files/converted.png",
        root: root,
        static_path: static_path)
      assert actual == expected
    end
  end
end
