defmodule Site.ScheduleV2ControllerTest do
  use Site.ConnCase, async: true

  @moduletag :external

  describe "Bus" do
    test "all stops is assigned for a route", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "1"))
      html_response(conn, 200)
      assert conn.assigns.all_stops != nil
    end

    test "origin is unassigned for a route when you first view the page", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "1"))
      html_response(conn, 200)
      assert conn.assigns.origin == nil
    end

    test "has the origin when it has been selected", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "1", origin: "2167", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
    end

    test "finds a trip when origin has been selected", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "1", origin: "2167", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
      assert conn.assigns.trip_info
    end

    test "finds a trip list with origin and destination", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "1", origin: "2167", destination: "82", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
      assert conn.assigns.destination.id == "82"
      assert conn.assigns.trip_info
      assert conn.assigns.schedules != nil
      assert conn.assigns.predictions != nil
    end

    test "assigns tab to \"trip-view\"", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "1"))
      assert conn.assigns.tab == "trip-view"
    end

    test "uses a direction id to determine which stops to show", %{conn: conn} do
      conn = get(conn, line_path(conn, :show, "1", direction_id: 0))
      assert conn.assigns.branches |> List.first() |> Map.get(:stops) |> Enum.map(& &1.id) |> Enum.member?("109")
      conn = get(conn, line_path(conn, :show, "1", direction_id: 1))
      refute conn.assigns.branches |> List.first() |> Map.get(:stops) |> Enum.map(& &1.id) |> Enum.member?("109")
    end
  end

  describe "commuter rail" do
    test "show timetable if no tab is specified", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "CR-Worcester"))
      assert redirected_to(conn, 302) =~ "timetable"
    end

    test "assigns information for the trip view", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "CR-Worcester", origin: "Westborough"))
      assert conn.assigns.tab == "trip-view"
      refute conn.assigns.schedules == nil
      refute conn.assigns.predictions == nil
      assert conn.assigns.trip_info
    end

    test "assigns information for the timetable", %{conn: conn} do
      conn = get(conn, timetable_path(conn, :show, "CR-Lowell", direction_id: 0))
      assert conn.assigns.tab == "timetable"
      assert conn.assigns.offset
      assert conn.assigns.alerts
      assert conn.assigns.trip_schedules
      assert conn.assigns.trip_messages
    end

    test "assigns trip messages for a few route/directions", %{conn: conn} do
      for {route_id, direction_id, expected_size} <- [
            {"CR-Lowell", 1, 0},
            {"CR-Haverhill", 0, 2},
            {"CR-Franklin", 1, 4}
          ] do
          path = timetable_path(conn, :show, route_id, direction_id: direction_id)
          conn = get(conn, path)
          assert map_size(conn.assigns.trip_messages) == expected_size
      end
    end

    test "header schedules are sorted correctly", %{conn: conn} do
      conn = get(conn, timetable_path(conn, :show, "CR-Lowell"))

      assert conn.assigns.header_schedules == conn.assigns.timetable_schedules
      |> Schedules.Sort.sort_by_first_times
      |> Enum.map(&List.first/1)
    end

    test "assigns a map of stop ID to zone", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "CR-Lowell"))
      zone_map = conn.assigns.zone_map

      assert "North Billerica" in Map.keys(zone_map)
      assert zone_map["North Billerica"] == "5"
    end

    test "renders a rating error if we get no_service back from the API", %{conn: conn} do
      conn = conn
      |> assign(:all_stops, {:error, [%JsonApi.Error{code: "no_service", meta: %{"version" => "Spring"}}]})
      |> get(timetable_path(conn, :show, "CR-Lowell", date: "2016-01-01"))

      response = html_response(conn, 200)
      assert response =~ "January 1, 2016 is not part of the Spring schedule."
    end
  end

  describe "subway" do
    test "assigns schedules, frequency table, origin, and destination", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "Red", origin: "place-sstat", destination: "place-brdwy", direction_id: 0))
      assert conn.assigns.schedules
      refute conn.assigns.schedules == []
      assert conn.assigns.stop_times
      assert conn.assigns.frequency_table
      assert conn.assigns.origin
      assert conn.assigns.destination
    end

    test "assigns schedules, frequency table, and origin", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "Red", origin: "place-sstat"))
      assert conn.assigns.schedules
      assert conn.assigns.frequency_table
      assert conn.assigns.stop_times
      assert conn.assigns.origin
      refute conn.assigns.destination
    end

   test "frequency table not assigned when no origin is selected", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "Red"))
      refute :frequency_table in Map.keys(conn.assigns)
      refute conn.assigns.origin
      refute :schedules in Map.keys(conn.assigns)
    end

    test "frequency table does not have negative values for Green Line", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "Green", origin: "place-north", vehicle_tooltips: %{}))
      for frequency <- conn.assigns.frequency_table do
        assert frequency.min_headway > 0
        assert frequency.max_headway > 0
      end
    end

    test "assigns schedules, frequency table, and origin for green line", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "Green-C", origin: "place-pktrm"))
      assert conn.assigns.schedules
      assert conn.assigns.stop_times.times
      assert conn.assigns.frequency_table
      assert conn.assigns.origin
      refute conn.assigns.destination
    end

    test "assigns schedules, frequency table, origin, destination for green line", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "Green-B", origin: "place-bland", destination: "place-pktrm",
                                      direction_id: "1"))
      assert conn.assigns.schedules
      refute conn.assigns.schedules == []
      assert conn.assigns.stop_times.times
      assert conn.assigns.frequency_table
      assert conn.assigns.origin
      assert conn.assigns.destination
    end

    test "assigns trip info and stop times for mattapan line", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "Mattapan", origin: "place-butlr", direction_id: "1"))
      assert conn.assigns.trip_info
      refute Enum.empty?(conn.assigns.stop_times)
    end
  end

  describe "all modes" do
    test "assigns breadcrumbs", %{conn: conn} do
      conn = get(conn, trip_view_path(conn, :show, "1"))
      assert conn.assigns.breadcrumbs
    end
  end

  describe "line tabs" do
    test "Commuter Rail data", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "CR-Lowell", direction_id: 1)
      assert html_response(conn, 200) =~ "Lowell Line"
      assert %Plug.Conn{assigns: %{branches: [%Stops.RouteStops{stops: stops}]}} = conn

      # make sure each stop has a zone
      for stop <- stops do
        assert stop.zone
      end

      # stops are in inbound order
      assert List.first(stops).id == "Lowell"
      assert List.last(stops).id == "place-north"

      # includes the stop features
      assert List.last(stops).stop_features == [
        :orange_line,
        :green_line,
        :bus,
        :access,
        :parking_lot
      ]

      # builds a map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"

      # assigns 3 holidays
      assert Enum.count(conn.assigns.holidays) == 3
    end

    test "Ferry data", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "Boat-F1", direction_id: 0)
      assert html_response(conn, 200) =~ "Hingham Ferry"
      assert %Plug.Conn{assigns: %{branches: [%Stops.RouteStops{stops: stops}]}} = conn

      # inbound order
      assert List.first(stops).id == "Boat-Long"
      assert List.last(stops).id == "Boat-Hingham"

      # Map
      assert conn.assigns.map_img_src =~ "ferry-spider"
    end

    test "Bus data", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "66", direction_id: 1)
      assert %Plug.Conn{assigns: %{branches: [%Stops.RouteStops{stops: stops}]}} = conn
      assert html_response(conn, 200) =~ "Route 66"
      assert Enum.find(stops, & &1.id == "926")
      assert List.last(stops).id == "64000"

      # Map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    test "Red Line data", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "Red", direction_id: 0)
      assert %Plug.Conn{assigns: %{branches: branches}} = conn
      assert html_response(conn, 200) =~ "Red Line"

      assert [%Stops.RouteStops{branch: nil, stops: unbranched_stops},
              %Stops.RouteStops{branch: "Braintree", stops: braintree},
              %Stops.RouteStops{branch: "Ashmont", stops: ashmont}] = branches

      # stops are in southbound order
      assert List.first(unbranched_stops).id == "place-alfcl"
      assert List.last(unbranched_stops).id == "place-jfk"

      assert List.last(ashmont).id == "place-asmnl"

      assert List.last(braintree).id == "place-brntn"

      # includes the stop features
      assert unbranched_stops |> List.first() |> Map.get(:stop_features) == [:bus, :access, :parking_lot]

      # spider map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    test "Green Line data", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "Green", direction_id: 0)
      assert html_response(conn, 200) =~ "Green Line"

      # stops are in Westbound order, Lechmere -> Boston College (last stop on B)
      {_, first_stop} = List.first(conn.assigns.all_stops)
      {_, last_stop} = List.last(conn.assigns.all_stops)
      assert first_stop.id == "place-lech"
      assert last_stop.id == "place-lake"

      # includes the stop features
      assert first_stop.stop_features == [:bus, :access, :parking_lot]

      # spider map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    defp stop_ids(conn) do
      Enum.flat_map(conn.assigns.branches, fn %Stops.RouteStops{stops: stops} -> Enum.map(stops, & &1.id) end)
    end

    test "Green line shows all branches", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "Green")
      assert conn.status == 200
      stop_ids = stop_ids(conn)

      assert "place-symcl" in stop_ids
      assert "place-sougr" in stop_ids # Green-B
      assert "place-kntst" in stop_ids # Green-C
      assert "place-rsmnl" in stop_ids # Green-D
      assert "place-nuniv" in stop_ids # Green-E
    end

    test "assigns 3 holidays", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "CR-Fitchburg")

      assert Enum.count(conn.assigns.holidays) == 3
    end

    test "Bus line with variant", %{conn: conn} do
      variant = "090112"
      conn = get conn, line_path(conn, :show, "9", direction_id: 1, variant: variant)

      # during the summer, the 9 only has 2 shapes. It has three when school
      # is in session.
      assert Enum.count(conn.assigns.route_shapes) >= 2
      assert "880" in List.last(conn.assigns.route_shapes).stop_ids
      assert variant == conn.assigns.active_shape.id
    end

    test "Bus line with correct default shape", %{conn: conn} do
      conn = get conn, line_path(conn, :show, "9", direction_id: 1)

      assert conn.assigns.active_shape.id == "090111"
    end

    test "sets schedule link to current direction for last stop and opposite for all other stops on non-bus lines", %{conn: conn} do
      response = conn
      |> get(line_path(conn, :show, "CR-Fitchburg", direction_id: 0))
      |> html_response(200)

      [last_stop | others] = response
      |> Floki.find(".schedule-link")
      |> Enum.reverse()

      assert last_stop |> Floki.attribute("href") |> List.first() =~ "direction_id=1"
      refute others |> List.last |> Floki.attribute("href") |> List.first =~ "direction_id=1"
      Enum.each(others, & assert &1 |> Floki.attribute("href") |> List.first() =~ "direction_id=0")
    end
  end

  test "renders a rating error if we get no_service back from the API", %{conn: conn} do
    conn = conn
    |> assign(:all_stops, {:error, [%JsonApi.Error{code: "no_service", meta: %{"version" => "Spring"}}]})
    |> get(trip_view_path(conn, :show, "1", date: "2016-01-01"))

    response = html_response(conn, 200)
    assert response =~ "January 1, 2016 is not part of the Spring schedule."
  end

  describe "tab redirects" do
    test "timetable tab", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "CR-Worcester", tab: "timetable", origin: "place-sstat"))
      path = redirected_to(conn, 302)
      path =~ timetable_path(conn, :show, "CR-Worcester")
      path =~ "origin=place-sstat"
      refute path =~ "tab="
    end

    test "trip_view tab", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1", tab: "trip-view", origin: "64", destination: "6"))
      path = redirected_to(conn, 302)
      path =~ trip_view_path(conn, :show, "1")
      path =~ "origin=64"
      path =~ "destination=6"
    end

    test "line tab as default", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1"))
      assert redirected_to(conn, 302) == line_path(conn, :show, "1")
    end

    test "line tab", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Red", tab: "line"))
      assert redirected_to(conn, 302) == line_path(conn, :show, "Red")
    end
  end
end
