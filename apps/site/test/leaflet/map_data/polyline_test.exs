defmodule Leaflet.MapData.PolylineTest do
  use ExUnit.Case, async: true
  alias Leaflet.MapData.Polyline

  @route_patterns_repo_api Application.get_env(:route_patterns, :route_patterns_repo_api)

  describe "new/2" do
    test "turns a polyline into a struct" do
      route_pattern =
        @route_patterns_repo_api.by_route_id("77")
        |> List.first()

      assert %Polyline{color: color, positions: positions} =
               Polyline.new(route_pattern, color: "#FF0000")

      assert color == "#FF0000"
      assert [first | _] = positions
      assert first == [42.37427, -71.11901]
    end

    test "makes polyline with default options" do
      route_pattern =
        @route_patterns_repo_api.by_route_id("77")
        |> List.first()

      assert %Polyline{color: color, positions: positions} = Polyline.new(route_pattern)

      assert color == "#000000"
      assert [first | _] = positions
      assert first == [42.37427, -71.11901]
    end
  end
end
