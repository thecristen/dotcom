defmodule GoogleMaps.MapData.MarkerTest do
  use ExUnit.Case
  import GoogleMaps.MapData.Marker
  alias GoogleMaps.MapData.Marker

  @boston_commons %Marker {
    latitude: "42.355041",
    longitude: "-71.066065",
    icon: nil,
    visible?: true
  }

  @public_garden %Marker {
    latitude: "42.354153",
    longitude: "-71.070547",
    icon: nil,
    visible?: false
  }

  describe "format_static_marker/1" do
    test "returns formatted latitude and longitude" do
      assert format_static_marker(@boston_commons) == "42.355041,-71.066065"
      assert format_static_marker(@public_garden) ==  "42.354153,-71.070547"
    end
  end
end
