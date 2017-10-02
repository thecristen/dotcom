defmodule Routes.PdfTest do
  use ExUnit.Case, async: true
  import Routes.Pdf
  alias Routes.Route

  describe "url/1" do
    test "returns the MBTA url if it exists for that route" do
      route1 = %Route{id: "1"}
      route2 = %Route{id: "CR-Fitchburg"}
      route3 = %Route{id: "Boat-F4"}

      assert url(route1) == "/sites/default/files/route_pdfs/route001.pdf"
      assert url(route2) == "/sites/default/files/route_pdfs/fitchburg.pdf"
      assert url(route3) == "/sites/default/files/route_pdfs/routeF4.pdf?led=7/8/2016%201:50:02%20PM"
    end

    test "returns nil if nothing exists for that route" do
      route = %Route{id: "nonexistent"}
      assert url(route) == nil
    end
  end

  describe "dated_urls/2" do
    test "given a date, returns upcoming schedule PDFs" do
      route = %Route{id: "CR-Fairmount"}
      expected = [
        {~D[2017-01-01], url(route)},
        {~D[2017-05-22], "/sites/default/files/route_pdfs/Fairmont%20WEB%20052217%20V1.pdf"},
      ]
      actual = dated_urls(route, ~D[2017-03-15])

      assert actual == expected
    end

    test "filters out schedules once a new one is in effect" do
      route = %Route{id: "CR-Worcester"}
      expected = [
        {~D[2017-05-22], "/sites/default/files/route_pdfs/Worcester%20WEB%20052217%20V1(1).pdf"}
      ]
      assert dated_urls(route, ~D[2017-05-22]) == expected
      assert dated_urls(route, ~D[2017-05-23]) == expected
    end

    test "returns an nil, nil if there isn't a matching route" do
      route = %Route{id: "nonexistent"}
      assert dated_urls(route, ~D[2017-01-01]) == []
    end
  end
end
