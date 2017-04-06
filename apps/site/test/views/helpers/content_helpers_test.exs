defmodule Site.ContentHelpersTest do
  use ExUnit.Case, async: true
  import Site.ContentHelpers

  describe "content/1" do
    test "given a populated string" do
      assert content("some content") == "some content"
    end

    test "given an empty string" do
      assert content("") == nil
    end

    test "given a empty string with whitespace" do
      assert content(" ") == nil
    end

    test "given a populated string, marked as safe" do
      assert content({:safe, "content"}) == {:safe, "content"}
    end

    test "given an empty string, marked as safe" do
      assert content({:safe, ""}) == nil
    end

    test "given an empty string with whitespace, marked as safe" do
      assert content({:safe, " "}) == nil
    end

    test "given nil" do
      assert content(nil) == nil
    end
  end
end
