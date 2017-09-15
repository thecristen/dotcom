defmodule TripPlan.ItineraryTest do
  use ExUnit.Case, async: true
  import TripPlan.Itinerary
  alias TripPlan.{TransitDetail, Api.MockPlanner, Leg, PersonalDetail, TransitDetail}

  @from MockPlanner.random_stop()
  @to MockPlanner.random_stop()

  describe "route_ids/1" do
    test "returns all the route IDs from the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      test_calculated_ids = Enum.flat_map(itinerary, fn leg ->
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
      test_calculated_ids = Enum.flat_map(itinerary, fn leg ->
        case leg.mode do
          %TransitDetail{trip_id: trip_id} -> [trip_id]
          _ -> []
        end
      end)
      assert test_calculated_ids == trip_ids(itinerary)
    end
  end

  describe "route_trip_ids/1" do
    test "returns all the route and trip IDs from the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      test_calculated_ids = Enum.flat_map(itinerary.legs, fn leg ->
        case leg.mode do
          %TransitDetail{} = td -> [{td.route_id, td.trip_id}]
          _ -> []
        end
      end)
      assert test_calculated_ids == route_trip_ids(itinerary)
    end
  end

  describe "positions/1" do
    test "returns all named positions for the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      [first, second] = itinerary.legs
      expected = [first.from, first.to, second.from, second.to]
      assert positions(itinerary) == expected
    end
  end

  describe "destination/1" do
    test "returns the final destination of the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      assert destination(itinerary) == @to
    end
  end

  describe "stop_ids/1" do
    test "returns all the stop IDs from the itinerary" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      first_leg = Enum.at(itinerary, 0)
      last_leg = Enum.at(itinerary, -1)
      test_calculated_ids = Enum.uniq([first_leg.from.stop_id, last_leg.from.stop_id, last_leg.to.stop_id])
      assert test_calculated_ids == stop_ids(itinerary)
    end
  end

  describe "walking_distance/1" do
    test "calculates walking distance of itinerary" do
      itinerary = %TripPlan.Itinerary{
        start: DateTime.from_unix(10),
        stop: DateTime.from_unix(13),
        legs: [
          %Leg{mode: %PersonalDetail{distance: 12.3}},
          %Leg{mode: %TransitDetail{}},
          %Leg{mode: %PersonalDetail{distance: 34.5}},
        ],
      }
      assert abs(walking_distance(itinerary) - 46.8) < 0.001
    end
  end

  describe "duration/1" do
    test "is greater than 0" do
      for _ <- 0..10 do
        {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
        assert duration(itinerary) > 0
      end
    end
  end
end
