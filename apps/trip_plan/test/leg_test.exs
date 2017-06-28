defmodule TripPlan.LegTest do
  use ExUnit.Case, async: true
  import TripPlan.Leg
  alias TripPlan.Api.MockPlanner

  @from MockPlanner.random_stop()
  @to MockPlanner.random_stop()
  @start ~N[2017-01-01T00:00:00]
  @stop ~N[2017-01-01T23:59:59]

  describe "route_id/1" do
    test "returns {:ok, id} for a transit leg" do
      transit_leg = MockPlanner.transit_leg(@from, @to, @start, @stop)
      route_id = transit_leg.mode.route_id
      assert {:ok, ^route_id} = route_id(transit_leg)
    end

    test "returns :error for a personal leg" do
      personal_leg = MockPlanner.personal_leg(@from, @to, @start, @stop)
      assert :error = route_id(personal_leg)
    end
  end

  describe "trip_id/1" do
    test "returns {:ok, id} for a transit leg" do
      transit_leg = MockPlanner.transit_leg(@from, @to, @start, @stop)
      trip_id = transit_leg.mode.trip_id
      assert {:ok, ^trip_id} = trip_id(transit_leg)
    end

    test "returns :error for a personal leg" do
      personal_leg = MockPlanner.personal_leg(@from, @to, @start, @stop)
      assert :error = trip_id(personal_leg)
    end
  end

  describe "stop_ids/1" do
    test "returns the stop IDs @from and @to" do
      transit_leg = MockPlanner.transit_leg(@from, @to, @start, @stop)
      assert [@from.stop_id, @to.stop_id] == stop_ids(transit_leg)
    end

    test "ignores nil stop IDs" do
      from = %{@from | stop_id: nil}
      personal_leg = MockPlanner.personal_leg(from, @to, @start, @stop)
      assert [@to.stop_id] == stop_ids(personal_leg)
    end
  end
end
