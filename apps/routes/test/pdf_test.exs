defmodule Routes.PdfTest do
  use ExUnit.Case, async: true
  alias Routes.Route

  test "url/1 returns the MBTA url if it exists for that route" do
    route1 = %Route{id: "1"}
    route2 = %Route{id: "CR-Fitchburg"}
    route3 = %Route{id: "Boat-F4"}

    assert Routes.Pdf.url(route1) == "http://mbta.com/uploadedFiles/Documents/Schedules_and_Maps/Bus/route001.pdf"
    assert Routes.Pdf.url(route2) == "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter_Rail/fitchburg.pdf"
    assert Routes.Pdf.url(route3) == "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Boats/routeF4.pdf?led=7/8/2016%201:50:02%20PM"
  end

  test "url/1 returns nil if nothing exists for that route" do
    route = %Route{id: "nonexistent"}
    assert Routes.Pdf.url(route) == nil
  end
end
