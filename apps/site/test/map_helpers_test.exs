defmodule MapHelpersTest do
  use Site.ConnCase, async: true
  alias Routes.Route
  import Site.MapHelpers

  describe "map_pdf_url/1" do
    test "returns the map link for subway" do
      assert map_pdf_url(:subway)  == static_url(Site.Endpoint, "/sites/default/files/maps/Rapid_Transit_Map.pdf")
    end

    test "returns the map link for ferry" do
      assert map_pdf_url(:ferry)  == static_url(Site.Endpoint, "/sites/default/files/maps/Ferry_Map.pdf")
    end

    test "returns the bus map for bus" do
      assert map_pdf_url(:bus)  == static_url(Site.Endpoint, "/sites/default/files/maps/Full_System_Map.pdf")
    end

    test "returns the map link for commuter rail" do
      assert map_pdf_url(:commuter_rail)  == static_url(Site.Endpoint, "/sites/default/files/maps/Commuter_Rail_Map.pdf")
    end

    test "works when given a route type number instead of an atom" do
      assert map_pdf_url(1)  == static_url(Site.Endpoint, "/sites/default/files/maps/Rapid_Transit_Map.pdf")
      assert map_pdf_url(4)  == static_url(Site.Endpoint, "/sites/default/files/maps/Ferry_Map.pdf")
    end

    test "gives nil when the number does not correspond to a route type" do
      assert map_pdf_url(9)  == nil
    end
  end

  describe "map_image_url/1" do
    test "returns a map image url for the subway" do
      assert map_image_url(:subway) == static_url(Site.Endpoint, "/images/map_thumbnails/Rapid_Transit_Map.png")
    end

    test "returns a map image url for the bus" do
      assert map_image_url(:bus) == static_url(Site.Endpoint, "/images/map_thumbnails/Full_System_Map.png")
    end

    test "returns a map image url for the commuter rail" do
      assert map_image_url(:commuter_rail) == static_url(Site.Endpoint, "/images/map_thumbnails/Commuter_Rail_Map.png")
    end

    test "returns a map image url for the ferry" do
      assert map_image_url(:ferry) == static_url(Site.Endpoint, "/images/map_thumbnails/Ferry_Map.png")
    end

    test "works with numbers instead of route type atoms" do
      assert map_image_url(2) == static_url(Site.Endpoint, "/images/map_thumbnails/Commuter_Rail_Map.png")
      assert map_image_url(1) == static_url(Site.Endpoint, "/images/map_thumbnails/Rapid_Transit_Map.png")
    end

    test "gives nil when the number does not correspond to a route type" do
      assert map_image_url(9)  == nil
    end
  end

  describe "route_map_color/1" do
    test "correct color is returned for each route" do
      assert route_map_color(%Route{type: 3}) == "FFCE0C"
      assert route_map_color(%Route{type: 2}) == "A00A78"
      assert route_map_color(%Route{id: "Blue"}) == "0064C8"
      assert route_map_color(%Route{id: "Red"}) == "FF1428"
      assert route_map_color(%Route{id: "Mattapan"}) == "FF1428"
      assert route_map_color(%Route{id: "Orange"}) == "FF8200"
      assert route_map_color(%Route{id: "Green"}) == "428608"
      assert route_map_color(%Route{id: "OTHER"}) == "000000"
    end
  end

  describe "map_stop_icon_path" do
    test "returns correct path when size is not :mid" do
      assert map_stop_icon_path(:tiny) =~ "000000-dot"
    end

    test "returns correct path when size is :mid" do
      assert map_stop_icon_path(:mid) =~ "000000-dot-mid"
    end

    test "returns correct path when 'filled' is specified and size" do
      assert map_stop_icon_path(:mid, true) == "000000-dot-filled-mid"
    end
    test "returns orrect path when 'filled' is true" do
      assert map_stop_icon_path(:tiny, true) == "000000-dot-filled"
    end
  end
end
