defmodule TripPlan.ItineraryTest do
  use ExUnit.Case, async: true
  import TripPlan.Itinerary
  alias TripPlan.{TransitDetail, Api.MockPlanner}

  @from MockPlanner.random_stop()
  @to MockPlanner.random_stop()

  describe "route_ids/1" do
    test "returns all the route IDs from the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      test_calculated_ids = Enum.flat_map(itinerary.legs, fn leg ->
        case leg.mode do
          %TransitDetail{route_id: route_id} -> [route_id]
          _ -> []
        end
      end)
      assert test_calculated_ids == route_ids(itinerary)
    end
  end

  describe "trip_ids/1" do
    test "returns all the trip IDs from the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      test_calculated_ids = Enum.flat_map(itinerary.legs, fn leg ->
        case leg.mode do
          %TransitDetail{trip_id: trip_id} -> [trip_id]
          _ -> []
        end
      end)
      assert test_calculated_ids == trip_ids(itinerary)
    end
  end

  describe "stop_ids/1" do
    test "returns all the stop IDs from the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      first_leg = List.first(itinerary.legs)
      last_leg = List.last(itinerary.legs)
      test_calculated_ids = Enum.uniq([first_leg.from.stop_id, last_leg.from.stop_id, last_leg.to.stop_id])
      assert test_calculated_ids == stop_ids(itinerary)
    end
  end
end
