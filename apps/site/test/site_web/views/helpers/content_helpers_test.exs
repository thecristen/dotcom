defmodule SiteWeb.ContentHelpersTest do
  use ExUnit.Case, async: true
  import SiteWeb.ContentHelpers

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

  describe "cms_route_to_class/1" do
    test "renders news entries" do
      assert cms_route_to_class(%{id: "Red", group: "line", mode: "subway"}) == "red-line"
      assert cms_route_to_class(%{id: "mattapan", group: "branch", mode: "subway"}) == "red-line"
      assert cms_route_to_class(%{id: "commuter_rail", group: "mode"}) == "commuter-rail"
      assert cms_route_to_class(%{id: "66", group: "route", mode: "bus"}) == "bus"
      assert cms_route_to_class(%{id: "silver_line", group: "line", mode: "bus"}) == "silver-line"
      assert cms_route_to_class(%{id: "local_bus", group: "custom", mode: "bus"}) == "bus"
    end
  end
end
