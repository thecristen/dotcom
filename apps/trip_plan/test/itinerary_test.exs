defmodule TripPlan.ItineraryTest do
  use ExUnit.Case, async: true
  import TripPlan.Itinerary
  alias TripPlan.{TransitDetail, Api.MockPlanner}

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

  describe "same_itinerary?" do
    test "Same itinerary is the same" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      assert same_itinerary?(itinerary, itinerary)
    end

    test "itineraries with different start times are not the same" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      later_itinerary = %{itinerary | start: Timex.shift(itinerary.start, minutes: 40)}
      refute same_itinerary?(itinerary, later_itinerary)
    end

    test "Itineraries with different accessibility flags are the same" do
      {:ok, [itinerary]} = MockPlanner.plan(@from, @to, [])
      accessible_itinerary = %{itinerary | accessible?: true}
      assert same_itinerary?(itinerary, accessible_itinerary)
    end
  end
end
