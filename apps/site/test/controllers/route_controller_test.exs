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
      # Stop list
      assert conn.assigns.stop_list_template == "_stop_list.html"

      # includes the stop features
      assert %{} = conn.assigns.stop_features
      assert conn.assigns.stop_features["place-north"] == [
        :green_line,
        :orange_line,
        :bus,
        :access
      ]

      # builds a map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    test "Red Line data", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Red")
      assert conn.status == 200

      # stops are in southbound order, Ashmont branch
      assert List.first(conn.assigns.stops).id == "place-alfcl"
      assert List.last(conn.assigns.stops).id == "place-asmnl"
      assert conn.assigns.merge_stop_id == "place-jfk"
      # Braintree branch
      assert List.first(conn.assigns.braintree_branch_stops).id == "place-nqncy"
      assert List.last(conn.assigns.braintree_branch_stops).id == "place-brntn"
      # List template
      assert conn.assigns.stop_list_template == "_stop_list_red.html"

      # includes the stop features
      assert %{} = conn.assigns.stop_features
      assert conn.assigns.stop_features["place-nqncy"] == [:bus, :access]

      # builds a map
      assert conn.assigns.map_img_src =~ "subway-spider"
    end
  end
end
