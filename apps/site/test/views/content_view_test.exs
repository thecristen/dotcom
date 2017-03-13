defmodule Site.ContentViewTest do
  use ExUnit.Case, async: true

  import Site.ContentView

  describe "field_has_content?/1" do
    test "it is true given a populated string" do
      assert field_has_content?("some content")
    end

    test "it is true given a populated list" do
      assert field_has_content?(["some content"])
    end

    test "it is false given an empty string" do
      refute field_has_content?("")
    end

    test "it is false given a whitespace-only string" do
      refute field_has_content?(" ")
    end

    test "it is false given an empty list" do
      refute field_has_content?([])
    end

    test "it is false given an empty map" do
      refute field_has_content?(%{})
    end
  end
end
