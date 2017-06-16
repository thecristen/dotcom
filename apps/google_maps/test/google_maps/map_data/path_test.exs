defmodule GoogleMaps.MapData.PathTest do
  use ExUnit.Case
  import GoogleMaps.MapData.Path
  alias GoogleMaps.MapData.Path

  @path %Path {
    weight: 4,
    color: "#fff",
    polyline: "Polyline"
  }

  describe "format_static_path/1" do
    test "formats a path" do
      expected = "weight:4|color:#fff|enc:Polyline"
      assert format_static_path(@path) == expected
    end
  end
end
