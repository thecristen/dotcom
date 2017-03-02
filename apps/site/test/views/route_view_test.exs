defmodule Site.RouteViewTest do
  use Site.ConnCase, async: true
  import Site.RouteView
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "route_row/3" do
    test "returns route name with bubble and featured icons", %{conn: conn} do
      row =
        conn
        |> assign(:route, %Routes.Route{id: "Red", name: "Red Line"})
        |> route_row(%Stops.Stop{id: "stop", name: "Stop Name"}, [:bus, :subway], false)
        |> safe_to_string
      assert row =~ "Stop Name"
      assert row =~ "trip-bubble"
      assert row =~ "bus"
      assert row =~ "subway"
    end
  end

  describe "route_row/3 for commuter rail" do
    test "returns route name with bubble, featured icons and zone", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{id: "CR-Providence", name: "Stoughton"})
      |> assign(:zones, %{"stop" => "A"})

      row = route_row(conn, %Stops.Stop{id: "stop", name: "Stop Name"}, [:bus, :subway], false)
      |> safe_to_string

      assert row =~ "Stop Name"
      assert row =~ "trip-bubble"
      assert row =~ "bus"
      assert row =~ "subway"
      assert row =~ "Zone A"
    end
  end
end
