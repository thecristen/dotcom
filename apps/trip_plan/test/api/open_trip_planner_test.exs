defmodule TripPlan.Api.OpenTripPlannerTest do
  use ExUnit.Case, async: true
  import TripPlan.Api.OpenTripPlanner

  describe "plan/3" do
    test "bad options returns an error" do
      expected = {:error, {:bad_param, {:bad, :arg}}}
      actual = plan({1, 1}, {2, 2}, bad: :arg)
      assert expected == actual
    end
  end
end
