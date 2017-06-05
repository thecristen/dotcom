defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}
  alias Stops.Stop
  import Site.ScheduleV2View
  import Site.ScheduleV2View.StopList, only: [add_expand_link?: 2,
                                              stop_bubble_content: 4, schedule_link_direction_id: 3,
                                              view_branch_link: 3, stop_bubble_location_display: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]

  @vehicle_tooltip %VehicleTooltip{
    prediction: %Predictions.Prediction{departing?: true, direction_id: 0, status: "On Time"},
    vehicle: %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: "Orange"},
    route: %Routes.Route{type: 2},
    trip_name: "101",
    stop_name: "South Station"
  }

  describe "stop_selector_suffix/2" do
    test "returns zones for commuter rail", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{type: 2})
      |> assign(:zone_map, %{"Lowell" => "6"})

      assert conn |> stop_selector_suffix("Lowell") |> IO.iodata_to_binary == "Zone 6"
    end

    test "if the stop has no zone, returns the empty string", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{type: 2})
      |> assign(:zone_map, %{})

      assert stop_selector_suffix(conn, "Wachusett")  == ""
    end

    test "returns a comma-separated list of lines for the green line", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{id: "Green"})
      |> assign(:stops_on_routes, GreenLine.stops_on_routes(0))

      assert conn |> stop_selector_suffix("place-pktrm") |> IO.iodata_to_binary == "B,C,D,E"
      assert conn |> stop_selector_suffix("place-lech") |> IO.iodata_to_binary == "E"
      assert conn |> stop_selector_suffix("place-kencl") |> IO.iodata_to_binary == "B,C,D"
    end

    test "for other lines, returns the empty string", %{conn: conn} do
      assert stop_selector_suffix(conn, "place-harsq") == ""
    end
  end

  describe "pretty_date/1" do
    test "it is today when the date given is todays date" do
      assert pretty_date(Util.service_date) == "Today"
    end

    test "it abbreviates the month when the date is not today" do
      date = ~D[2017-01-01]
      assert pretty_date(date) == "Jan 1"
    end
  end

  describe "display_direction/1" do
    test "given no schedules, returns no content" do
      assert display_direction(%StopTimeList{}) == ""
    end

    test "given a non-empty list of predicted_schedules, displays the direction of the first one's route" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}}
      trip = %Trip{direction_id: 1}
      stop_times = StopTimeList.build(
        [%Schedules.Schedule{route: route, trip: trip, stop: %Stop{id: "stop"}}],
        [],
        "stop",
        nil,
        :last_trip_and_upcoming,
        ~N[2017-01-01T06:30:00],
        true
      )
      assert stop_times |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end

    test "uses predictions if no schedule are available (as on subways)" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}, id: "1"}
      stop = %Stop{id: "stop"}
      now = Timex.now
      stop_times = StopTimeList.build_predictions_only(
        [],
        [%Predictions.Prediction{route: route, stop: stop, trip: nil, direction_id: 1,
                                                                      time: Timex.shift(now, hours: -1)}],
        stop.id,
        nil
      )
      assert stop_times |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end

  describe "stop_bubble_location_display/3" do

    test "when vehicle is not at stop and stop is not a terminus, returns an empty circle" do
      rendered = safe_to_string(stop_bubble_location_display(nil, %Routes.Route{type: 1}, false))
      assert rendered =~ "stop-bubble-stop"
      assert rendered =~ "svg"
    end

    test "when vehicle is not at stop and stop is a terminus, returns a filled circle" do
      rendered = safe_to_string(stop_bubble_location_display(nil, %Routes.Route{type: 1}, true))
      assert rendered =~ "stop-bubble-terminus"
      assert rendered =~ "svg"
    end

    test "when vehicle is at stop and stop is not a terminus, returns a normal vehicle circle icon" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, %Routes.Route{type: 1, id: "Orange"}, false))
      assert rendered =~ "icon-circle"
      assert rendered =~ "icon-boring"
    end

    test "when vehicle is at stop and stop is a terminus, returns an inverse vehicle circle icon" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, %Routes.Route{type: 1, id: "Orange"}, true))
      assert rendered =~ "icon-circle"
      assert rendered =~ "icon-inverse"
    end

    test "given a vehicle and the subway route_type, returns the icon for the subway" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, %Routes.Route{type: 1, id: "Orange"}, false))
      assert rendered =~ "icon-subway"
    end

    test "given a vehicle and the bus route_type, returns the icon for the bus" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, %Routes.Route{type: 3, id: "Orange"}, false))
      assert rendered =~ "icon-bus"
    end

    test "Does not show vehicle icon when vehicle is on a different route" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, %Routes.Route{type: 3, id: "Blue"}, false))
      refute rendered =~ "icon-bus"
      refute rendered =~ "icon-circle"
      assert rendered =~ "stop-bubble-stop"
      assert rendered =~ "svg"
    end
  end

  describe "timetable_location_display/1" do
    test "given nil, returns the empty string" do
      assert timetable_location_display(nil) == ""
    end

    test "otherwise, displays the CR icon" do
      for status <- [:in_transit, :incoming, :stopped] do
        icon = svg_icon(%Site.Components.Icons.SvgIcon{icon: :commuter_rail, class: "icon-small", show_tooltip?: false})
        assert timetable_location_display(%Vehicles.Vehicle{status: status}) == icon
      end
    end
  end

  describe "tab_selected?/2" do
    test "true for the same two arguments" do
      assert tab_selected?("timetable", "timetable")
      assert tab_selected?("trip-view", "trip-view")
    end

    test "true for different arguments" do
      refute tab_selected?("trip-view", "timetable")
      refute tab_selected?("trip-view", "timetable")
    end
  end

  describe "template_for_tab/1" do
    test "returns the template corresponding to a tab value" do
      assert template_for_tab("trip-view") == "_trip_view.html"
      assert template_for_tab("timetable") == "_timetable.html"
    end
  end

  describe "reverse_direction_opts/4" do
    test "reverses direction when the stop exists in the other direction" do
      expected = [trip: nil, direction_id: "1", destination: "place-harsq", origin: "place-davis"]
      actual = reverse_direction_opts(%Stops.Stop{id: "place-harsq"}, %Stops.Stop{id: "place-davis"}, "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end

    test "reverses direction when origin and destination aren't selected" do
      expected = [trip: nil, direction_id: "1", destination: nil, origin: nil]
      actual = reverse_direction_opts(nil, nil, "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end

    test "maintains origin when there's no destination selected" do
      expected = [trip: nil, direction_id: "1", destination: nil, origin: "place-davis"]
      actual = reverse_direction_opts(%Stops.Stop{id: "place-davis"}, nil, "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end
  end

  describe "_trip_view.html" do
    test "renders a message if no scheduled trips", %{conn: conn} do
      conn = conn
      |> assign(:all_stops, [])
      |> assign(:date, ~D[2017-01-01])
      |> assign(:destination, nil)
      |> assign(:origin, nil)
      |> assign(:route, %Routes.Route{})
      |> assign(:direction_id, 1)
      |> assign(:show_date_select?, false)
      |> assign(:headsigns, %{0 => [], 1 => []})
      |> fetch_query_params

      output = Site.ScheduleV2View.render(
        "_trip_view.html",
        Keyword.merge(Keyword.new(conn.assigns), conn: conn)
      ) |> safe_to_string

      assert output =~ "There are no scheduled inbound trips on January 1, 2017."
    end
  end

  describe "_frequency.html" do
    test "renders a no service message if the block doesn't have service" do
      frequency_table = %Schedules.FrequencyList{frequencies: [%Schedules.Frequency{time_block: :am_rush}]}
      schedules = [%Schedules.Schedule{time: Util.now}]
      date = Util.service_date
      safe_output = Site.ScheduleV2View.render(
        "_frequency.html",
        frequency_table: frequency_table,
        schedules: schedules,
        date: date,
        route: %Routes.Route{id: "1", type: 3, name: "1"})
      output = safe_to_string(safe_output)
      assert output =~ "No service between these hours"
    end

    test "renders a headway if the block has service" do
      frequency = %Schedules.Frequency{time_block: :am_rush, min_headway: 5, max_headway: 10}
      frequency_table = %Schedules.FrequencyList{frequencies: [frequency]}
      schedules = [%Schedules.Schedule{time: Util.now}]
      date = Util.service_date
      safe_output = Site.ScheduleV2View.render(
        "_frequency.html",
        frequency_table: frequency_table,
        schedules: schedules,
        date: date,
        route: %Routes.Route{id: "1", type: 3, name: "1"})
      output = safe_to_string(safe_output)
      assert output =~ "5-10"
    end
  end

  describe "Schedule Alerts" do
    @route %Routes.Route{type: 1, id: "1"}
    @schedule %Schedule{route: @route, trip: %Trip{id: "trip"}, stop: %Stop{id: "stop"}}
    @prediction %Prediction{route: @route, trip: %Trip{id: "trip_pred"}, stop: %Stop{id: "stop_pred"}, status: "Nearby"}

    @alerts [
        %Alerts.Alert{
          informed_entity: [%Alerts.InformedEntity{direction_id: 1, route: "1", trip: "trip"}]
        },
        %Alerts.Alert{
          informed_entity: [%Alerts.InformedEntity{direction_id: 1, route: "1", trip: "trip_pred"}]
        },
        %Alerts.Alert{
          informed_entity: [%Alerts.InformedEntity{direction_id: 1, route: "1",  stop: "stop"}]
        },
        %Alerts.Alert{
          informed_entity: [%Alerts.InformedEntity{direction_id: 1, route: "1",  stop: "stop_pred"}]
        }
      ]

      test "trip alerts use schedule for match" do
        predicted_schedule = %PredictedSchedule{schedule: @schedule, prediction: @prediction}
        alert = List.first(trip_alerts(predicted_schedule, @alerts, @route, 1))
        assert List.first(alert.informed_entity).trip == "trip"
      end

      test "trip alerts use prediction if no schedule is available" do
        alert = List.first(trip_alerts(%PredictedSchedule{prediction: @prediction}, @alerts, @route, 1))
        assert List.first(alert.informed_entity).trip == "trip_pred"
      end

      test "No trip alerts returned if no predicted schedule is given" do
        alerts = trip_alerts(nil, @alerts, @route, 1)
        assert Enum.empty?(alerts)
      end

      test "No trip alerts return if empty predicted schedule is given" do
        alerts = trip_alerts(%PredictedSchedule{}, @alerts, @route, 1)
        assert alerts == []
      end

      test "Trip alerts are not returned for bus routes" do
        route = %Routes.Route{type: 3, id: "1"}
        alerts = trip_alerts(%PredictedSchedule{schedule: @schedule, prediction: @prediction}, @alerts, route, 1)
        assert alerts == []
      end

      test "stop alerts use schedule for match" do
        predicted_schedule = %PredictedSchedule{schedule: @schedule, prediction: @prediction}
        alert = List.first(stop_alerts(predicted_schedule, @alerts, "1", 1))
        assert List.first(alert.informed_entity).stop == "stop"
      end

      test "stop alerts use prediction if no schedule is avaulable" do
        alert = List.first(stop_alerts(%PredictedSchedule{prediction: @prediction}, @alerts, "1", 1))
        assert List.first(alert.informed_entity).stop == "stop_pred"
      end

      test "No stop alerts returned if no predicted schedule is given" do
        alerts = stop_alerts(nil, @alerts, "1", 1)
        assert Enum.empty?(alerts)
      end

      test "No stop alerts return if empty predicted schedule is given" do
        alerts = stop_alerts(%PredictedSchedule{}, @alerts, "1", 1)
        assert alerts == []
      end
  end

  describe "display_alerts/1" do
    test "alerts are not displayed if no alerts are given" do
      assert safe_to_string(display_alerts([])) == ""
    end

    test "Icon is displayed if alerts are given" do
      assert safe_to_string(display_alerts(["alert"])) =~ "icon-alert"
    end
  end

  describe "_trip_info.html" do
    test "make sure page reflects information from full_status function" do
      trip_info = %TripInfo{
        route: %Routes.Route{type: 2},
        vehicle: %Vehicles.Vehicle{status: :incoming},
        vehicle_stop_name: "Readville"
      }
      actual = Site.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info
      )
      expected = TripInfo.full_status(trip_info) |> IO.iodata_to_binary
      assert safe_to_string(actual) =~ expected
    end
  end

  describe "_trip_info_row.html" do
    @vehicle %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: "1"}
    @output Site.ScheduleV2View.render(
            "_trip_info_row.html",
            name: "name",
            href: "",
            above_expand_link?: true,
            is_last_item?: false,
            vehicle?: true,
            vehicle_tooltip: %{@vehicle_tooltip | vehicle: @vehicle},
            terminus?: true,
            alerts: ["alert"],
            predicted_schedule: %PredictedSchedule{prediction: @prediction, schedule: @schedule},
            route: %Routes.Route{id: "1", type: 3,})

    test "real time icon shown when prediction is available" do
      safe_output = safe_to_string(@output)
      assert safe_output =~ "rss"
    end

    test "Alert icon is shown when alerts are not empty" do
      safe_output = safe_to_string(@output)
      assert safe_output =~ "icon-alert"
    end

    test "Alert icon is shown with tooltip attributes" do
      safe_output = safe_to_string(@output)
      alert = Floki.find(safe_output, ".icon-alert")
      assert Floki.attribute(alert, "data-toggle") == ["tooltip"]
      assert Floki.attribute(alert, "title") == ["Service alert or delay"]
    end

    test "shows vehicle icon when vehicle location is available" do
      safe_output = safe_to_string(@output)
      assert safe_output =~ "icon-bus"
    end
  end

  describe "_line.html" do
    @shape %Routes.Shape{id: "test", name: "test", stop_ids: [], direction_id: 0}
    @hours_of_operation %{
      saturday: %{
        0 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]},
        1 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]}
      },
      sunday: %{
        0 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]},
        1 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]}
      },
      week: %{
        0 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]},
        1 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]}
      }
    }

    test "Bus line with variant filter", %{conn: conn} do
      output = Site.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [{[:terminus], %Stops.RouteStop{id: "stop 1", name: "Stop 1"}},
                          {[:terminus], %Stops.RouteStop{id: "stop 2", name: "Stop 2"}}],
              all_shapes: [@shape, @shape],
              active_shape: @shape,
              expanded: nil,
              show_variant_selector: true,
              map_img_src: nil,
              hours_of_operation: @hours_of_operation,
              holidays: [],
              branches: [%Stops.RouteStops{branch: nil, stops: [%Stops.RouteStop{id: "stop 1", name: "Stop 1"},
                                                                %Stops.RouteStop{id: "stop 2", name: "Stop 2"}]}],
              origin: nil,
              destination: nil,
              direction_id: 1,
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              direction_id: 1,
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})

      assert safe_to_string(output) =~ "shape-filter"
    end

    test "Bus line without variant filter", %{conn: conn} do
      output = Site.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [{[:terminus], %Stops.RouteStop{id: "stop 1", branch: nil, name: "Stop 1"}},
                          {[:terminus], %Stops.RouteStop{id: "stop 2", branch: nil, name: "Stop 2"}}],
              all_shapes: [@shape],
              expanded: nil,
              active_shape: nil,
              map_img_src: nil,
              hours_of_operation: @hours_of_operation,
              holidays: [],
              branches: [%Stops.RouteStops{
                          branch: nil,
                          stops: [%Stops.RouteStop{id: "stop 1", branch: nil, name: "Stop 1"},
                                  %Stops.RouteStop{id: "stop 2", branch: nil, name: "Stop 2"}]}],
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              destination: nil,
              origin: nil,
              direction_id: 1,
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})

      refute safe_to_string(output) =~ "shape-filter"
    end
  end

  describe "frequency_times/2" do
    test "returns \"Every X mins\" if there is service during a time block" do
      frequency = %Schedules.Frequency{max_headway: 11, min_headway: 3, time_block: :am_rush}
      rendered = true |> Site.ScheduleV2View.frequency_times(frequency) |> safe_to_string
      assert rendered =~ "Every 3-11"
      assert rendered =~ "mins"
      assert rendered =~ "minutes"
    end

    test "returns \"No service between these hours\" if there is no service" do
      actual = false |> Site.ScheduleV2View.frequency_times(%Schedules.Frequency{}) |> safe_to_string
      assert actual == "<span>No service between these hours</span>"
    end
  end

  describe "display_frequency_departure/2" do
    test "AM Rush displays first departure" do
      assert safe_to_string(display_frequency_departure(:am_rush, Util.now(), Util.now())) =~ "First Departure"
    end

    test "Late Night displays last departure" do
      assert safe_to_string(display_frequency_departure(:late_night, Util.now(), Util.now())) =~ "Last Departure"
    end

    test "Other time blocks do no give departure" do
      refute display_frequency_departure(:evening, Util.now(), Util.now())
      refute display_frequency_departure(:midday, Util.now(), Util.now())
    end

    test "Ultimate departure text not shown if not given time" do
      refute display_frequency_departure(:am_rush, nil, Util.now())
      refute display_frequency_departure(:late_night, Util.now(), nil)
    end
  end

  describe "no_trips_message/5" do
    test "when a no service error is provided" do
      error = [%JsonApi.Error{code: "no_service", meta: %{"version" => "Spring 2017 version 3D"}}]
      result = no_trips_message(error, nil, nil, nil, ~D[2017-01-01])
      assert IO.iodata_to_binary(result) == "January 1, 2017 is not part of the Spring schedule."
    end
    test "when a starting and ending stop are provided" do
      result = no_trips_message(nil, %Stops.Stop{name: "The Start"}, %Stops.Stop{name: "The End"}, nil, ~D[2017-03-05])
      assert IO.iodata_to_binary(result) == "There are no scheduled trips between The Start and The End on March 5, 2017."
    end

    test "when a direction is provided" do
      result = no_trips_message(nil, nil, nil, "Inbound", ~D[2017-03-05])
      assert IO.iodata_to_binary(result) == "There are no scheduled inbound trips on March 5, 2017."
    end

    test "fallback when nothing is available" do
      result = no_trips_message(nil, nil, nil, nil, nil)
      assert IO.iodata_to_binary(result) == "There are no scheduled trips."
    end
  end

  describe "clear_selector_link/1" do
    test "returns the empty string when clearable? is false" do
      assert clear_selector_link(%{clearable?: false, selected: "place-davis"}) == ""
    end

    test "returns the empty string when selecte is nil" do
      assert clear_selector_link(%{clearable?: true, selected: nil}) == ""
    end

    test "otherwise returns a link setting the query_key to nil", %{conn: conn} do
      result = %{
        clearable?: true,
        selected: "place-davis",
        placeholder_text: "destination",
        query_key: "destination",
        conn: fetch_query_params(conn)
      }
      |> clear_selector_link()
      |> safe_to_string

      assert result =~ "(clear<span class=\"sr-only\"> destination</span>)"
      refute result =~ "place-davis"
    end
  end

  describe "stop_name_link_with_alerts/3" do
    test "adds a no-wrap around the last word of the link text and the icon" do
      alerts = [%Alerts.Alert{}]
      result = stop_name_link_with_alerts("name", "url", alerts)
      assert result |> Phoenix.HTML.safe_to_string  =~ "<a href=\"url\">"
      assert result |> Phoenix.HTML.safe_to_string  =~ "<span class=\"inline-block\">name<svg"
    end

    test "when there are no alerts, just makes a link" do
      alerts = []
      result = stop_name_link_with_alerts("name", "url", alerts)
      assert result |> Phoenix.HTML.safe_to_string  =~ "<a href=\"url\">"
      refute result |> Phoenix.HTML.safe_to_string  =~ "<svg"
    end
  end

  describe "view_branch_link/3" do
    test "generates a link to view the given branch", %{conn: conn} do
      link = conn
      |> fetch_query_params
      |> view_branch_link("braintree", "Braintree")
      |> safe_to_string
      |> Floki.find(".branch-link")

      assert link |> Floki.text |> String.trim() =~ "View Braintree Branch"
      assert link |> Floki.attribute("href") |> List.first =~ "?expanded=Braintree"
    end
  end

  describe "display_map_link?/1" do
    test "is true for subway and ferry" do
      assert display_map_link?(4) == true
    end

    test "is false for subway, bus and commuter rail" do
      assert display_map_link?(0) == false
      assert display_map_link?(3) == false
      assert display_map_link?(2) == false
    end
  end

  describe "route_pdf_link/2" do
    test "returns a link to PDF redirector if we have a PDF for the route" do
      route = %Routes.Route{id: "CR-Worcester", name: "Fairmount", type: 2}
      rendered = safe_to_string(route_pdf_link(route, ~D[2017-01-01]))
      assert rendered =~ "View PDF of Fairmount line paper schedule"
      assert rendered =~ "View PDF of upcoming schedule — effective May 22"
    end

    test "has the correct text for a bus route" do
      route = %Routes.Route{id: "741", name: "SL1", type: 3}
      rendered = safe_to_string(route_pdf_link(route, ~D[2017-01-01]))
      assert rendered =~ "View PDF of Route SL1 paper schedule"
    end

    test "returns an empty list if no PDF for that route" do
      route = %Routes.Route{id: "nonexistent"}
      assert route_pdf_link(route, ~D[2017-01-01]) == []
    end
  end

  describe "trip_expansion_link/3" do
    @date ~D[2017-05-05]

    test "Does not return link when no expansion", %{conn: conn} do
      refute trip_expansion_link(:none, @date, conn)
    end

    test "Shows expand link when collapsed", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert safe_to_string(trip_expansion_link(:collapsed, @date, conn)) =~ "Show all trips for"
    end

    test "Shows collapse link when expanded", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert safe_to_string(trip_expansion_link(:expanded, @date, conn)) =~ "Show upcoming trips only"
    end
  end

  describe "_empty.html" do
    @date ~D[2016-01-01]

    test "shows date reset link when not current date", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      rendered = Site.ScheduleV2View.render("_empty.html",
                                            error: nil,
                                            origin: "origin",
                                            destination: "dest",
                                            direction: "inbound",
                                            date: @date,
                                            conn: conn)
      assert safe_to_string(rendered) =~ "View inbound trips"
    end

    test "Does not show reset link if selected date is service date", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      rendered = Site.ScheduleV2View.render("_empty.html",
                                            error: nil,
                                            origin: "origin",
                                            destination: "dest",
                                            direction: "inbound",
                                            date: Util.service_date(),
                                            conn: conn)
      refute safe_to_string(rendered) =~ "View inbound trips"
    end
  end

  describe "direction_tooltip/1" do
    test "gives commuter rail specific advice" do
      assert direction_tooltip(2) =~ "Schedule times are shown for the direction displayed in the box below. Click on the box to change direction. Inbound trips go to Boston, and outbound trips leave from there."
    end

    test "gives ferry specific advice" do
      assert direction_tooltip(4) =~ "Schedule times are shown for the direction displayed in the box below. Click on the box to change direction. Inbound trips go to Boston, and outbound trips leave from there."
    end

    test "gives generic advice for the other modes" do
      assert direction_tooltip(0) =~ "Schedule times are shown for the direction displayed in the box below. Click on the box to change direction."
    end
  end

  describe "date_tooltip/0" do
    test "makes a schedule tooltip" do
      assert date_tooltip() =~ "class='schedule-tooltip'"
    end
  end

  describe "get expected column width in each use case" do
    test "forced 6 column" do
      assert direction_select_column_width(true, 40) == "6"
    end

    test "long headsign column" do
      assert direction_select_column_width(nil, 40) == "8"
    end

    test "short headsign column" do
      assert direction_select_column_width(false, 10) == "4"
    end
  end

  describe "south_station_commuter_rail/1" do
    test "returns nothing if the route does not go to south station" do
      route = %Routes.Route{id: "CR-Fitchburg"}

      assert south_station_commuter_rail(route) == []
    end

    test "returns the pdf for back bay to south station schedules if the route does go to south station" do
      route = %Routes.Route{id: "CR-Providence"}

      text = south_station_commuter_rail(route) |> Phoenix.HTML.safe_to_string
      assert text =~ "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter_Rail/southstation_backbay.pdf"
    end
  end

  describe "add_expand_link/2" do
    test "returns false for unbranched stops" do
      assert add_expand_link?(%Stops.RouteStop{id: "place-forhl", branch: nil},
                              %{nil => ["place-forhl", "place-1", "place-2"]}) == false
    end

    test "returns true for the first branched stop" do
      green_line = %{
        "Green-B" => ["place-bland", "place-lake"],
        "Green-C" => ["place-smary", "place-clmnl"],
      }
      assert add_expand_link?(%Stops.RouteStop{id: "place-smary", branch: "Green-C"}, green_line) == true
    end

    test "returns false for all other branched stops" do
      green_line = %{
        "Green-B" => ["place-bland", "place-lake"],
        "Green-C" => ["place-smary", "place-clmnl"],
      }
      assert add_expand_link?(%Stops.RouteStop{id: "place-griggs", branch: "Green-B"}, green_line) == false
    end
  end

  def render_stop_bubble_content(assigns, bubble_type, branch, index) do
    assigns
    |> stop_bubble_content(bubble_type, branch, index)
    |> Enum.map(& if &1 == "", do: "", else: safe_to_string(&1))
    |> Enum.join()
  end

  describe "stop_bubble_content" do

    test "returns a bubble with a vehicle and tool tip" do
      stop = %Stops.RouteStop{id: "stop", branch: nil, is_terminus?: true, stop_number: 0}
      route = %Routes.Route{id: "route"}
      vehicle_tooltip = %VehicleTooltip{
        prediction: %Predictions.Prediction{departing?: true, direction_id: 0, status: "On Time"},
        vehicle: %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: "route"},
        route: %Routes.Route{type: 2},
        trip_name: "101",
        stop_name: "South Station"
      }
      assigns = %{expanded: nil, stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: vehicle_tooltip}
      content = render_stop_bubble_content(assigns, :terminus, nil, 0)
      assert content =~ "train 101 has arrived at South Station"
      assert content =~ "icon-subway-image"
    end

    test "returns a terminus bubble and a solid line for the first terminus" do
      stop = %Stops.RouteStop{id: "stop", branch: nil, is_terminus?: true, stop_number: 0}
      route = %Routes.Route{id: "route"}
      assigns = %{expanded: nil, stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: nil}
      content = render_stop_bubble_content(assigns, :terminus, nil, 0)
      assert content =~ "stop-bubble-terminus"
      assert content =~ "route-branch-stop-bubble-line solid"
      refute content =~ "route-branch-indent-start"
    end

    test "returns only a terminus bubble for the last terminus" do
      stop = %Stops.RouteStop{id: "stop", branch: nil, is_terminus?: true, stop_number: 10}
      route = %Routes.Route{id: "route"}
      assigns = %{expanded: nil, stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: nil}
      content = render_stop_bubble_content(assigns, :terminus, nil, 10)
      assert content =~ "stop-bubble-terminus"
      refute content =~ "route-branch-stop-bubble-line"
      refute content =~ "route-branch-indent-start"
    end

    test "returns a stop bubble and a solid line for an unbranched stop" do
      stop = %Stops.RouteStop{id: "stop", branch: nil, is_terminus?: false, stop_number: 4}
      route = %Routes.Route{id: "route"}
      assigns = %{expanded: nil, stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: nil}
      content = render_stop_bubble_content(assigns, :stop, nil, 4)
      assert content =~ "stop-bubble-stop"
      assert content =~ "route-branch-stop-bubble-line solid"
      refute content =~ "route-branch-indent-start"
    end

    test "returns a stop bubble and a solid line for a stop on an expanded branch" do
      stop = %Stops.RouteStop{id: "stop", branch: "branch", is_terminus?: false, stop_number: 4}
      route = %Routes.Route{id: "route"}
      assigns = %{expanded: "branch", stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: nil}
      content = render_stop_bubble_content(assigns, :stop, "branch", 4)
      assert content =~ "stop-bubble-stop"
      assert content =~ "route-branch-stop-bubble-line solid"
      refute content =~ "route-branch-indent-start"
    end

    test "returns only a dotted line if the stop is not on the branch and the branch is collapsed" do
      stop = %Stops.RouteStop{id: "stop", branch: "branch", is_terminus?: false, stop_number: 4}
      route = %Routes.Route{id: "route"}
      assigns = %{expanded: nil, stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: nil}
      content = render_stop_bubble_content(assigns, :line, "other branch", 4)
      refute content =~ "stop-bubble-stop"
      assert content =~ "route-branch-stop-bubble-line dotted"
      refute content =~ "route-branch-indent-start"
    end

    test "returns only a solid line if the stop is not on the branch and the branch is expanded" do
      stop = %Stops.RouteStop{id: "stop", branch: "other branch", is_terminus?: false, stop_number: 4}
      route = %Routes.Route{id: "route"}
      assigns = %{expanded: "branch", stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: nil}
      content = render_stop_bubble_content(assigns, :line, "branch", 4)
      refute content =~ "stop-bubble-stop"
      assert content =~ "route-branch-stop-bubble-line solid"
      refute content =~ "route-branch-indent-start"
    end

    test "returns dotted route-branch-index-start div for a merge stop" do
      stop = %Stops.RouteStop{id: "stop", branch: "other branch", is_terminus?: false, stop_number: 4}
      route = %Routes.Route{id: "route"}
      assigns = %{expanded: nil, stop: stop, route: route, is_expand_link?: false, vehicle_tooltip: nil}
      content = render_stop_bubble_content(assigns, :merge, "branch", 4)
      refute content =~ "stop-bubble-stop"
      assert content =~ "route-branch-stop-bubble-line dotted"
      assert content =~ "route-branch-indent-start"
    end
  end

  describe "trip_list_bubble" do
    test "returns a stop bubble with the correct branch letter on green line" do
      assert "Green-B" |> trip_list_bubble() |> safe_to_string() =~ ">B</text>"
      assert "Green-C" |> trip_list_bubble() |> safe_to_string() =~ ">C</text>"
      assert "Green-D" |> trip_list_bubble() |> safe_to_string() =~ ">D</text>"
      assert "Green-E" |> trip_list_bubble() |> safe_to_string() =~ ">E</text>"
    end

    test "returns an empty safe for all other routes" do
      assert trip_list_bubble("Red") |> Phoenix.HTML.safe_to_string() == ""
      assert trip_list_bubble("CR-Newburyport") |> Phoenix.HTML.safe_to_string() == ""
      assert trip_list_bubble("anything") |> Phoenix.HTML.safe_to_string() == ""
    end
  end

  describe "schedule_link_direction_id" do
    test "returns opposite of direction id for the last stop on a line" do
      assert schedule_link_direction_id(%Stops.RouteStop{stop_number: 10}, [{:terminus, "branch1"}], 0) == 1
      assert schedule_link_direction_id(%Stops.RouteStop{stop_number: 15},
                                        [{:line, "branch1"}, {:terminus, "branch2"}], 1) == 0
      assert schedule_link_direction_id(%Stops.RouteStop{stop_number: 13},
                                        [{:stop, "branch1"}, {:terminus, "branch2"}, {:line, "branch3"}], 0) == 1
    end

    test "returns direction id for all other stops" do
      assert schedule_link_direction_id(%Stops.RouteStop{stop_number: 0}, [{:terminus, "branch1"}], 0) == 0
      assert schedule_link_direction_id(%Stops.RouteStop{stop_number: 3}, [{:stop, "branch1"}], 0) == 0
      assert schedule_link_direction_id(%Stops.RouteStop{stop_number: 5}, [{:line, "branch1"}], 1) == 1
      assert schedule_link_direction_id(%Stops.RouteStop{stop_number: 10},
                                                         [{:line, "branch1"}, {:stop, "branch2"}], 1) == 1
    end
  end

  describe "trip_link/4" do
    @trip_info %TripInfo{sections: [[%PredictedSchedule{prediction: %Predictions.Prediction{trip: %Trip{id: "1"}}}]]}

    test "trip link for non-matching trip", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, false, "2") == "/?trip=2#2"
    end

    test "trip link for matching, un-chosen stop", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, false, "1") == "/?trip=1#1"
    end

    test "trip link for matching, chosen stop", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, true, "1") == "/?trip=#1"
    end
  end
end
