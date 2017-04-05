defmodule Content.HelpersTest do
  use ExUnit.Case, async: true

  import Content.Helpers

  describe "rewrite_url/1" do
    test "rewrites when the URL has query params" do
      rewritten = rewrite_url("http://test-mbta.pantheonsite.io/foo/bar?baz=quux")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar?baz=quux"])
    end

    test "rewrites when the URL has no query params" do
      rewritten = rewrite_url("http://test-mbta.pantheonsite.io/foo/bar")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar"])
    end

    test "rewrites the URL for https" do
      rewritten = rewrite_url("https://example.com/foo/bar")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar"])
    end
  end
end
