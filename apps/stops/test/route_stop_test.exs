defmodule Stops.RouteStopTest do
  use ExUnit.Case, async: true

  import Stops.RouteStop

  describe "build_route_stop/3" do
    test "creates a RouteStop object with all expected attributes" do
      stop = %Stops.Stop{name: "Braintree", id: "place-brntn"}
      result = build_route_stop({{stop, true}, 2000}, %Routes.Shape{name: "Braintree"}, %Routes.Route{id: "Red", type: 1})
      assert result.id == "place-brntn"
      assert result.route.id == "Red"
      assert result.name == "Braintree"
      assert result.station_info == stop
      assert result.is_terminus? == true
      assert result.zone == "2"
      assert result.stop_number == 2000
    end
  end
end
