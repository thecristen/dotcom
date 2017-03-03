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

      # make sure each stop has a zone
      for stop <- conn.assigns.stops do
        assert conn.assigns.zones[stop.id]
      end

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

    test "Green line does not show branched route data", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Green")
      assert conn.status == 200
      stop_ids = Enum.map(conn.assigns.stops, & &1.id)

      refute "place-kntst" in stop_ids # Green-C
      refute "place-symcl" in stop_ids # Green-E
    end

    test "Green line terminals shown if branch not expanded", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Green")
      assert conn.status == 200
      stop_ids = Enum.map(conn.assigns.stops, & &1.id)

      assert "place-lake" in stop_ids
      assert "place-clmnl" in stop_ids
      assert "place-hsmnl" in stop_ids
    end

    test "Green line shows individual branch when expanded", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "Green", expanded: "Green-E")
      assert conn.status == 200
      stop_ids = Enum.map(conn.assigns.stops, & &1.id)

      assert "place-symcl" in stop_ids
      assert "place-nuniv" in stop_ids
      refute "place-kntst" in stop_ids # Green-C
    end

    test "assigns 3 holidays", %{conn: conn} do
      conn = get conn, route_path(conn, :show, "CR-Fitchburg")

      assert Enum.count(conn.assigns.holidays) == 3
    end
  end

  describe "hours_of_operation/2" do
    defp schedules_fn(opts) do
      date_time = Timex.to_datetime(opts[:date])
      [
        %Schedules.Schedule{time: Timex.set(date_time, hour: 6), trip: %Schedules.Trip{direction_id: 0}},
        %Schedules.Schedule{time: Timex.set(date_time, hour: 23), trip: %Schedules.Trip{direction_id: 0}},
        %Schedules.Schedule{time: Timex.set(date_time, hour: 6), trip: %Schedules.Trip{direction_id: 1}},
        %Schedules.Schedule{time: Timex.set(date_time, hour: 23), trip: %Schedules.Trip{direction_id: 1}},
      ]
    end

    test "if route is nil, assigns nothing", %{conn: conn} do
      conn = conn
      |> assign(:route, nil)
      |> assign(:date, ~D[2017-02-28])
      |> Site.RouteController.hours_of_operation([])

      refute Map.has_key?(conn.assigns, :hours_of_operation)
    end

    test "assigns week, saturday, and sunday departures in both directions", %{conn: conn} do
      conn = %{conn | params: %{"route" => "Teal"}}
      |> assign(:route, %Routes.Route{id: "Teal"})
      |> assign(:date, ~D[2017-02-28]) # Tuesday
      |> Site.RouteController.hours_of_operation(schedules_fn: &schedules_fn/1)

      assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 6
      assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 23
      assert conn.assigns.hours_of_operation[:week][1].first_departure.day == 6 # Monday
      assert conn.assigns.hours_of_operation[:sunday][1].first_departure.day == 5
      assert conn.assigns.hours_of_operation[:saturday][1].first_departure.day == 4
    end

    test "uses schedules for each Green line branch", %{conn: conn} do
      conn = %{conn | params: %{"route" => "Green"}}
      |> assign(:route, nil)
      |> assign(:date, ~D[2017-02-28])
      |> Site.RouteController.hours_of_operation(schedules_fn: &schedules_fn/1)

      assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 6
      assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 23
    end
  end

  describe "next_3_holidays/2" do
    test "gets 3 results", %{conn: conn} do
      conn = conn
      |> assign(:date, ~D[2017-02-28])
      |> Site.RouteController.next_3_holidays([])

      assert Enum.count(conn.assigns.holidays) == 3
    end

    test "if there is no date, doesnt assign holidays", %{conn: conn} do
      conn = conn
      |> Site.RouteController.next_3_holidays([])

      refute conn.assigns[:holidays]
    end
  end
end
