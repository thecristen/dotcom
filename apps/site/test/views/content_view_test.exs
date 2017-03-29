defmodule Site.ContentViewTest do
  use ExUnit.Case, async: true
  import Site.ContentView

  describe "field_has_content?/1" do
    test "true given a populated string" do
      assert field_has_content?("some content")
    end

    test "true given a populated list" do
      assert field_has_content?(["some content"])
    end

    test "false given nil" do
      refute field_has_content?(nil)
    end

    test "false given an empty string" do
      refute field_has_content?("")
    end

    test "false given a whitespace-only string" do
      refute field_has_content?(" ")
    end

    test "false given an empty list" do
      refute field_has_content?([])
    end

    test "false given an empty map" do
      refute field_has_content?(%{})
    end

    test "false given an empty Phoenix.Safe.HTML.t" do
      refute field_has_content?(Phoenix.HTML.raw(""))
    end

    test "true given a Phoenix.Safe.HTML.t with content" do
      assert field_has_content?(Phoenix.HTML.raw("some content"))
    end
  end
end
