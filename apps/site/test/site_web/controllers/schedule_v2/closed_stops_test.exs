defmodule SiteWeb.ScheduleV2Controller.ClosedStopsTest do
  use ExUnit.Case, async: true
  alias SiteWeb.ScheduleV2Controller.ClosedStops

  @moduletag :external
  @stop %Stops.Stop{id: "stop-id", name: "stop-name"}
  @route_stop %Stops.RouteStop{id: "stop-id", name: "stop-name"}

  describe "wollaston_stop/1" do
    test "Builds proper struct for for Stops.Stop" do
      result = ClosedStops.wollaston_stop(@stop)

      assert result.name == "Wollaston"
      assert result.id == "place-wstn"
      assert result.closed_stop_info.reason == "closed for renovation"
      assert result.closed_stop_info.info_link == "/projects/wollaston-station/project-updates/how-the-wollaston-station-improvements-affect-your-trip"
    end

    test "Builds proper struct for for Stops.RouteStop" do
      result = ClosedStops.wollaston_stop(@route_stop)

      assert result.name == "Wollaston"
      assert result.id == "place-wstn"
      assert result.closed_stop_info.reason == "closed for renovation"
      assert result.closed_stop_info.info_link == "/projects/wollaston-station/project-updates/how-the-wollaston-station-improvements-affect-your-trip"
    end
  end
end
