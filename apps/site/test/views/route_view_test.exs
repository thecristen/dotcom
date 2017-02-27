defmodule Site.RouteViewTest do
  use Site.ConnCase, async: true
  import Site.RouteView
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "route_row/3" do
    test "returns route name with featured icons", %{conn: conn} do
      row = route_row(conn, [:bus, :subway], %Stops.Stop{id: "stop", name: "Stop Name"})
      assert safe_to_string(row) =~ "Stop Name"
      assert safe_to_string(row) =~ "bus"
      assert safe_to_string(row) =~ "subway"
    end
  end
end
