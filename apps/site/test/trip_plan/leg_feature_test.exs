defmodule Site.TripPlan.LegFeatureTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Site.TripPlan.LegFeature
  alias TripPlan.Api.MockPlanner
  import Site.ViewHelpers, only: [svg: 1, hyphenated_mode_string: 1]
  import Phoenix.HTML, only: [safe_to_string: 1]

  @from MockPlanner.random_stop()
  @to MockPlanner.random_stop()
  @start ~N[2017-01-01T00:00:00]
  @stop ~N[2017-01-01T23:59:59]

  describe "leg_feature/2" do
    test "works for all kinds of transit legs" do
      for _ <- 0..5 do
        transit_leg = MockPlanner.transit_leg(@from, @to, @start, @stop)
        expected_icon_class = transit_leg.mode.route_id
        |> Routes.Repo.get
        |> Site.Components.Icons.SvgIcon.get_icon_atom
        |> hyphenated_mode_string
        feature = leg_feature(transit_leg, route_by_id: &Routes.Repo.get/1)
        assert safe_to_string(feature) =~ expected_icon_class
      end
    end

    test "works for all kinds of personal legs" do
      for _ <- 0..5 do
        personal_leg = MockPlanner.personal_leg(@from, @to, @start, @stop)
        expected_icon = case personal_leg.mode.type do
                          :walk -> svg("walk.svg")
                          :drive -> svg("car.svg")
                        end
        feature = leg_feature(personal_leg, [])
        assert safe_to_string(feature) =~ safe_to_string(expected_icon)
      end
    end
  end
end
