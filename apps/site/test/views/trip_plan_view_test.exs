defmodule Site.TripPlanViewTest do
  use ExUnit.Case, async: true
  import Site.TripPlanView
  alias TripPlan.Api.MockPlanner

  @from MockPlanner.random_stop()
  @to MockPlanner.random_stop()
  @start ~N[2017-01-01T00:00:00]
  @stop ~N[2017-01-01T23:59:59]

  describe "leg_feature/2" do
    test "works for all kinds of transit legs" do
      for _ <- 0..10 do
        transit_leg = MockPlanner.transit_leg(@from, @to, @start, @stop)
        route_id = transit_leg.mode.route_id
        route_map = %{
          route_id => Routes.Repo.get(route_id)
        }
        assert leg_feature(transit_leg, route_map)
      end
    end

    test "works for all kinds of personal legs" do
      for _ <- 0..10 do
        personal_leg = MockPlanner.personal_leg(@from, @to, @start, @stop)
        assert leg_feature(personal_leg, %{})
      end
    end
  end

  describe "input_class/2" do
    test "returns trip-plan-current-location if the relevant lat and lng are set" do
      from_current_location = %{"from_latitude" => "42.349159", "from_longitude" => "-71.0655084"}
      assert location_input_class(from_current_location, :from) == "trip-plan-current-location"
      assert location_input_class(from_current_location, :to) == ""
    end

    test "returns the empty string if only one of latitude or longitude is set" do
      params = %{"from_latitude" => "42.349159", "to_latitude" => ""}
      assert location_input_class(params, :from) == ""
    end

    test "returns the empty string if both lat and lng are blank" do
      params = %{"from_latitude" => "", "to_latitude" => ""}
      assert location_input_class(params, :from) == ""
    end
  end
end
