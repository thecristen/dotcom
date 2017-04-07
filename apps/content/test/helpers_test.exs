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

  describe "parse_updated_at/1" do
    test "handles unix time as a string" do
      api_data = %{"changed" => [%{"value" => "1488904773"}]}

      unix =
      api_data
      |> parse_updated_at
      |> DateTime.to_unix

      assert unix == 1_488_904_773
    end

    test "handles unix time as an int" do
      api_data = %{"changed" => [%{"value" => 1_488_904_773}]}

      unix =
      api_data
      |> parse_updated_at
      |> DateTime.to_unix

      assert unix == 1_488_904_773
    end
  end

  describe "int_or_string_to_int/1" do
    test "converts appropriately or leaves alone" do
      assert int_or_string_to_int(5) == 5
      assert int_or_string_to_int("5") == 5
    end

    test "handles nil" do
      assert int_or_string_to_int(nil) == nil
    end
  end
end
