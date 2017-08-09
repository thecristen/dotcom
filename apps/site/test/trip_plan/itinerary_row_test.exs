defmodule TripPlan.ItineraryRowTest do
  use ExUnit.Case, async: true

  import Site.TripPlan.ItineraryRow
  alias Site.TripPlan.ItineraryRow
  alias Routes.Route

  describe "route_id/1" do
    test "returns the route id when a route is present" do
      row = %ItineraryRow{route: %Route{id: "route"}}

      assert route_id(row) == "route"
    end

    test "returns nil when a route is not present" do
      row = %ItineraryRow{route: nil}

      refute route_id(row)
    end
  end

  describe "route_type/1" do
    test "returns the route type when a route is present" do
      row = %ItineraryRow{route: %Route{type: 0}}

      assert route_type(row) == 0
    end

    test "returns nil when a route is not present" do
      row = %ItineraryRow{route: nil}

      refute route_type(row)
    end
  end

  describe "route_name/1" do
    test "returns the route name when a route is present" do
      row = %ItineraryRow{route: %Route{name: "Red Line"}}

      assert route_name(row) == "Red Line"
    end

    test "returns nil when a route is not present" do
      row = %ItineraryRow{route: nil}

      refute route_name(row)
    end
  end
end
