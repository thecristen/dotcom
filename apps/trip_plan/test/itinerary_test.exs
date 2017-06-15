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
end
