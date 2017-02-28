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

    test "Ferry data", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Boat-F1")
      assert conn.status == 200
      assert List.first(conn.assigns.stops).id == "Boat-Hingham"
      assert List.last(conn.assigns.stops).id == "Boat-Long"

      # Map
      assert conn.assigns.map_img_src =~ "ferry-spider"
    end

    test "Red Line data", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Red")
      assert conn.status == 200

      # stops are in southbound order, Ashmont branch
      assert List.first(conn.assigns.stops).id == "place-alfcl"
      assert List.last(conn.assigns.stops).id == "place-jfk"
      assert conn.assigns.merge_stop_id == "place-jfk"
      # List template
      assert conn.assigns.stop_list_template == "_stop_list_red.html"

      # includes the stop features
      assert %{} = conn.assigns.stop_features
      assert conn.assigns.stop_features["place-nqncy"] == [:bus, :access]

      # spider map
      assert conn.assigns.map_img_src =~ "subway-spider"
    end

    test "Red line initally has no Braintree or Ashmont data besides termini", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Red")
      assert conn.status == 200

      assert List.first(conn.assigns.braintree_branch_stops).id == "place-brntn"
      assert List.first(conn.assigns.ashmont_branch_stops).id == "place-asmnl"
    end

    test "Red line has braintree and ashmont stops when indicated in query params", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Red", expanded: "braintree")
      assert conn.status == 200
      stop_ids = Enum.map(conn.assigns.braintree_branch_stops, & &1.id)
      assert List.first(stop_ids) == "place-nqncy"
      assert List.last(stop_ids) == "place-brntn"
      assert Enum.count(conn.assigns.ashmont_branch_stops) == 1

      conn = get conn, route_path(conn, :show, "Red", expanded: "ashmont")
      stop_ids = Enum.map(conn.assigns.ashmont_branch_stops, & &1.id)
      assert List.first(stop_ids) == "place-shmnl"
      assert List.last(stop_ids) == "place-asmnl"
      assert Enum.count(conn.assigns.braintree_branch_stops) == 1
    end

    test "Green Line data", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Green")
      assert conn.status == 200

      # stops are in Westbound order, Lechmere -> Boston College (last stop on B)
      assert List.first(conn.assigns.stops).id == "place-lech"
      assert List.last(conn.assigns.stops).id == "place-lake"
      # List template
      assert conn.assigns.stop_list_template == "_stop_list_green.html"
      # Active lines
      assert conn.assigns.active_lines["place-north"] == %{"Green-B" => :empty, "Green-C" => :terminus, "Green-D" => :empty, "Green-E" => :stop}
      assert conn.assigns.active_lines["place-hsmnl"] == %{"Green-B" => :line, "Green-C" => :line, "Green-D" => :line, "Green-E" => :terminus} # Health
      assert conn.assigns.active_lines["place-hymnl"] == %{"Green-B" => :stop, "Green-C" => :stop, "Green-D" => :stop}

      # includes the stop features
      assert %{} = conn.assigns.stop_features
      assert conn.assigns.stop_features["place-pktrm"] == [:red_line, :access]

      # spider map
      assert conn.assigns.map_img_src =~ "subway-spider"
    end
  end
end
