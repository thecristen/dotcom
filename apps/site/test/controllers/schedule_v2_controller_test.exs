defmodule Site.ScheduleV2ControllerTest do
  use Site.ConnCase, async: true

  @moduletag :external

  describe "Bus" do
    test "all stops is assigned for a route", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1"))
      html_response(conn, 200)
      assert conn.assigns.all_stops != nil
    end

    test "origin is unassigned for a route when you first view the page", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1"))
      html_response(conn, 200)
      assert conn.assigns.origin == nil
    end

    test "has the origin when it has been selected", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1", origin: "2167", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
    end

    test "finds a trip when origin has been selected", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1", origin: "2167", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
      assert conn.assigns.trip_info
    end

    test "finds a trip list with origin and destination", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1", origin: "2167", destination: "82", direction_id: "1"))
      html_response(conn, 200)
      assert conn.assigns.origin.id == "2167"
      assert conn.assigns.destination.id == "82"
      assert conn.assigns.trip_info
      assert conn.assigns.schedules != nil
      assert conn.assigns.predictions != nil
    end

    test "assigns tab to \"trip-view\"", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1"))
      assert conn.assigns.tab == "trip-view"
    end

    test "uses a direction id to determine which stops to show", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1", direction_id: 0, tab: "line"))
      stops = conn.assigns.stops |> Enum.map(& &1.id)
      assert Enum.member?(stops, "109")
      conn = get(conn, schedule_path(conn, :show, "1", direction_id: 1, tab: "line"))
      stops = conn.assigns.stops |> Enum.map(& &1.id)
      refute Enum.member?(stops, "109")
    end
  end

  describe "commuter rail" do
    test "assigns the tab parameter if none is provided", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "CR-Worcester"))
      assert conn.assigns.tab == "timetable"
    end

    test "assigns information for the trip view", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "CR-Worcester", tab: "trip-view", origin: "Westborough"))
      assert conn.assigns.tab == "trip-view"
      refute conn.assigns.schedules == nil
      refute conn.assigns.predictions == nil
      assert conn.assigns.trip_info
    end

    test "assigns information for the timetable", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "CR-Lowell", tab: "timetable", direction_id: 0))
      assert conn.assigns.tab == "timetable"
      assert conn.assigns.offset
      assert conn.assigns.alerts
      assert conn.assigns.trip_schedules
      assert conn.assigns.trip_messages
    end

    test "assigns trip messages for a few route/directions", %{conn: conn} do
      for {route_id, direction_id, expected_size} <- [
            {"CR-Lowell", 0, 2},
            {"CR-Lowell", 1, 0},
            {"CR-Haverhill", 0, 2},
            {"CR-Franklin", 1, 4}
          ] do
          path = schedule_path(conn, :show, route_id, tab: "timetable", direction_id: direction_id)
          conn = get(conn, path)
          assert map_size(conn.assigns.trip_messages) == expected_size
      end
    end

    test "header schedules are sorted correctly", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "CR-Lowell", tab: "timetable"))

      assert conn.assigns.header_schedules == conn.assigns.timetable_schedules
      |> Schedules.Sort.sort_by_first_times
      |> Enum.map(&List.first/1)
    end

    test "assigns a map of stop ID to zone", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "CR-Lowell", tab: "trip-view"))
      zone_map = conn.assigns.zone_map

      assert "North Billerica" in Map.keys(zone_map)
      assert zone_map["North Billerica"] == "5"
    end

    test "renders a rating error if we get no_service back from the API", %{conn: conn} do
      conn = conn
      |> assign(:all_stops, {:error, [%JsonApi.Error{code: "no_service", meta: %{"version" => "Spring"}}]})
      |> get(schedule_path(conn, :show, "CR-Lowell", date: "2016-01-01", tab: "timetable"))

      response = html_response(conn, 200)
      assert response =~ "January 1, 2016 is not part of the Spring schedule."
    end
  end

  describe "subway" do
    test "assigns schedules, frequency table, origin, and destination", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Red", origin: "place-sstat", destination: "place-brdwy", direction_id: 0))
      assert conn.assigns.schedules
      refute conn.assigns.schedules == []
      assert conn.assigns.stop_times
      assert conn.assigns.frequency_table
      assert conn.assigns.origin
      assert conn.assigns.destination
    end

    test "assigns schedules, frequency table, and origin", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Red", origin: "place-sstat"))
      assert conn.assigns.schedules
      assert conn.assigns.frequency_table
      assert conn.assigns.stop_times
      assert conn.assigns.origin
      refute conn.assigns.destination
    end

   test "frequency table not assigned when no origin is selected", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Red"))
      refute :frequency_table in Map.keys(conn.assigns)
      refute conn.assigns.origin
      refute :schedules in Map.keys(conn.assigns)
    end

    test "frequency table does not have negative values for Green Line", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Green", origin: "place-north"))
      for frequency <- conn.assigns.frequency_table.frequencies do
        assert frequency.min_headway > 0
        assert frequency.max_headway > 0
      end
    end

    test "assigns schedules, frequency table, and origin for green line", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Green-C", origin: "place-pktrm"))
      assert conn.assigns.schedules
      assert conn.assigns.stop_times.times
      assert conn.assigns.frequency_table
      assert conn.assigns.origin
      refute conn.assigns.destination
    end

    test "assigns schedules, frequency table, origin, destination for green line", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Green-B", origin: "place-chill", destination: "place-pktrm", direction_id: "1"))
      assert conn.assigns.schedules
      refute conn.assigns.schedules == []
      assert conn.assigns.stop_times.times
      assert conn.assigns.frequency_table
      assert conn.assigns.origin
      assert conn.assigns.destination
    end

    test "assigns trip info and stop times for mattapan line", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Mattapan", origin: "place-butlr", direction_id: "1"))
      assert conn.assigns.trip_info
      refute Enum.empty?(conn.assigns.stop_times.times)
    end
  end

  describe "all modes" do
    test "assigns breadcrumbs", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "1"))
      assert conn.assigns.breadcrumbs
    end
  end

  describe "line tabs" do
    test "Commuter Rail data", %{conn: conn} do
      {date, date_time} = morning_date_time()

      conn = get conn, schedule_path(conn, :show,
        "CR-Lowell",
        tab: "line",
        date: Date.to_iso8601(date),
        date_time: DateTime.to_iso8601(date_time))
      assert html_response(conn, 200) =~ "Lowell Line"

      # make sure each stop has a zone
      for stop <- conn.assigns.stops do
        assert stop.zone
      end

      # stops are in outbound order
      assert List.first(conn.assigns.stops).id == "place-north"
      assert List.last(conn.assigns.stops).id == "Lowell"
      # Stop list
      assert conn.assigns.stop_list_template == "_stop_list.html"

      # includes the stop features
      assert List.first(conn.assigns.stops).stop_features == [
        :orange_line,
        :green_line,
        :bus,
        :access
      ]

      # builds a map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    test "Ferry data", %{conn: conn} do
      {date, dt} = morning_date_time()
      conn = get conn, schedule_path(conn, :show,
        "Boat-F1",
        tab: "line",
        date: Date.to_iso8601(date),
        date_time: NaiveDateTime.to_iso8601(dt))
      assert html_response(conn, 200) =~ "Hingham Ferry"
      # outbound order
      assert List.first(conn.assigns.stops).id == "Boat-Long"
      assert List.last(conn.assigns.stops).id == "Boat-Hingham"

      # Map
      assert conn.assigns.map_img_src =~ "ferry-spider"
    end

    test "Bus data", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "66", direction_id: 1, tab: "line")
      assert html_response(conn, 200) =~ "Route 66"
      assert Enum.find(conn.assigns.stops, & &1.id == "926")
      assert List.last(conn.assigns.stops).id == "64000"

      # Map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    test "Red Line data", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Red", tab: "line")
      assert html_response(conn, 200) =~ "Red Line"

      # stops are in southbound order, Ashmont branch
      assert List.first(conn.assigns.stops).id == "place-alfcl"
      assert List.last(conn.assigns.stops).id == "place-jfk"
      assert conn.assigns.merge_stop_id == "place-jfk"
      # List template
      assert conn.assigns.stop_list_template == "_stop_list_red.html"

      # includes the stop features
      assert conn.assigns.stops |> List.first() |> Map.get(:stop_features) == [:bus, :access]

      # spider map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    test "Red line initally has no Braintree or Ashmont data besides termini", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Red", tab: "line")
      assert conn.status == 200

      assert List.first(conn.assigns.braintree_branch_stops).id == "place-brntn"
      assert List.first(conn.assigns.ashmont_branch_stops).id == "place-asmnl"
    end

    test "Red line has braintree and ashmont stops when indicated in query params", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Red", expanded: "Braintree", tab: "line")
      assert conn.status == 200
      stop_ids = Enum.map(conn.assigns.braintree_branch_stops, & &1.id)
      assert List.first(stop_ids) == "place-nqncy"
      assert List.last(stop_ids) == "place-brntn"
      assert Enum.count(conn.assigns.ashmont_branch_stops) == 1

      conn = get conn, schedule_path(conn, :show, "Red", expanded: "Ashmont", tab: "line")
      stop_ids = Enum.map(conn.assigns.ashmont_branch_stops, & &1.id)
      assert List.first(stop_ids) == "place-shmnl"
      assert List.last(stop_ids) == "place-asmnl"
      assert Enum.count(conn.assigns.braintree_branch_stops) == 1
    end

    test "Green Line data", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Green", tab: "line")
      assert html_response(conn, 200) =~ "Green Line"

      # stops are in Westbound order, Lechmere -> Boston College (last stop on B)
      assert List.first(conn.assigns.stops_with_expands).id == "place-lech"
      assert List.last(conn.assigns.stops_with_expands).id == "place-lake"
      # List template
      assert conn.assigns.stop_list_template == "_stop_list_green.html"
      # Active lines
      assert conn.assigns.active_lines["place-north"] == %{"Green-B" => :empty, "Green-C" => :eastbound_terminus, "Green-D" => :empty, "Green-E" => :stop}
      assert conn.assigns.active_lines["place-hsmnl"] == %{"Green-B" => :line, "Green-C" => :line, "Green-D" => :line, "Green-E" => :westbound_terminus} # Health
      assert conn.assigns.active_lines["place-hymnl"] == %{"Green-B" => :stop, "Green-C" => :stop, "Green-D" => :stop}

      # includes the stop features
      assert %{} = conn.assigns.stop_features
      assert conn.assigns.stop_features["place-pktrm"] == [:red_line, :access]

      # spider map
      assert conn.assigns.map_img_src =~ "maps.googleapis.com"
    end

    defp stop_ids(conn) do
      Enum.flat_map(conn.assigns.stops_with_expands, fn
        {:expand, _, _} -> []
        stop -> [stop.id]
      end)
    end

    test "Green line does not show branched route data", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Green", tab: "line")
      assert conn.status == 200
      stop_ids = stop_ids(conn)

      refute "place-kntst" in stop_ids # Green-C
      refute "place-symcl" in stop_ids # Green-E
    end

    test "Green line terminals shown if branch not expanded", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Green", tab: "line")
      assert conn.status == 200
      stop_ids = stop_ids(conn)

      assert "place-lake" in stop_ids
      assert "place-clmnl" in stop_ids
      assert "place-hsmnl" in stop_ids
    end

    test "Green line shows individual branch when expanded", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "Green", expanded: "Green-E", tab: "line")
      assert conn.status == 200
      stop_ids = stop_ids(conn)

      assert "place-symcl" in stop_ids
      assert "place-nuniv" in stop_ids
      refute "place-kntst" in stop_ids # Green-C
    end

    test "assigns 3 holidays", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "CR-Fitchburg", tab: "line")

      assert Enum.count(conn.assigns.holidays) == 3
    end

    test "Bus line with variant", %{conn: conn} do
      variant = "090078"
      conn = get conn, schedule_path(conn, :show, "9", direction_id: 1, tab: "line", variant: variant)

      assert Enum.count(conn.assigns.shapes) == 3
      assert "1564" in List.last(conn.assigns.shapes).stop_ids
      assert variant == conn.assigns.active_shape.id
    end

    test "Bus line with correct default shape", %{conn: conn} do
      conn = get conn, schedule_path(conn, :show, "9", direction_id: 1, tab: "line")

      assert "090096" == conn.assigns.active_shape.id
    end
  end

  test "renders a rating error if we get no_service back from the API", %{conn: conn} do
    conn = conn
    |> assign(:all_stops, {:error, [%JsonApi.Error{code: "no_service", meta: %{"version" => "Spring"}}]})
    |> get(schedule_path(conn, :show, "1", date: "2016-01-01"))

    response = html_response(conn, 200)
    assert response =~ "January 1, 2016 is not part of the Spring schedule."
  end

  defp morning_date_time do
    date = Util.service_date()
    {:ok, naive_dt} = NaiveDateTime.new(date, ~T[12:00:00])
    {:ok, dt} = DateTime.from_naive(naive_dt, "Etc/UTC")
    {date, dt}
  end
end
