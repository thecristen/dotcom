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
end
