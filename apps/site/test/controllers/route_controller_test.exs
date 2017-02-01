defmodule Site.RouteControllerTest do
  use Site.ConnCase, async: true
  @moduletag :external

  describe "show/:id" do
    test "renders a 404 if the route ID doesn't exist", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "-1")
      assert conn.status == 404
      refute conn.assigns[:stops]
      assert conn.halted
    end

    test "Commuter Rail data", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "CR-Lowell")
      assert conn.status == 200

      # stops are in inbound order
      assert List.first(conn.assigns.stops).id == "Lowell"
      assert List.last(conn.assigns.stops).id == "place-north"

      # includes the stop features
      assert %{} = conn.assigns.stop_features
      assert conn.assigns.stop_features["place-north"] == [
        :green_line,
        :orange_line,
        :bus,
        :access
      ]

      # builds a map
      assert conn.assigns.map_img_src =~ "maps.google.com"
    end
  end
end
