defmodule Site.TripPlan.RelatedLinkTest do
  use ExUnit.Case, async: true
  import Site.TripPlan.RelatedLink
  import Site.Router.Helpers
  alias TripPlan.Itinerary

  setup do
    from = TripPlan.Api.MockPlanner.random_stop()
    to = TripPlan.Api.MockPlanner.random_stop()
    {:ok, [itinerary]} = TripPlan.plan(from, to, [])
    {:ok, %{itinerary: itinerary}}
  end

  describe "links_for_itinerary/1" do
    test "returns a list of related links", %{itinerary: itinerary} do
      {expected_route, expected_icon, expected_fare_mode} =
        case Itinerary.route_ids(itinerary) do
          ["Blue"] -> {"Blue Line schedules", :blue_line, :bus_subway}
          ["1"] -> {"Route 1 schedules", :bus, :bus_subway}
          ["CR-Lowell"] -> {"Lowell Line schedules", :commuter_rail, :commuter_rail}
        end

      assert [route_link, fare_link] = links_for_itinerary(itinerary)
      assert text(route_link) == expected_route
      assert route_link.icon_name == expected_icon
      assert fare_link.text == "View fare information"
      assert fare_link.url =~ fare_path(Site.Endpoint, :show, expected_fare_mode)
    end
  end
end
