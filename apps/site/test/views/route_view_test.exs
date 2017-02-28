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

  describe "next_3_holidays/0" do
    test "gets 3 results" do
      assert Enum.count(next_3_holidays()) == 3
    end
  end
end
