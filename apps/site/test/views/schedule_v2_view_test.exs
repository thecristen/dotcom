defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip, Departures}
  alias Stops.{Stop, RouteStop, RouteStops}
  import Site.ScheduleV2View
  import Site.ScheduleV2View.StopList, only: [add_expand_link?: 2]
  import Phoenix.HTML, only: [safe_to_string: 1]

  @trip %Schedules.Trip{name: "101", headsign: "Headsign", direction_id: 0, id: "1"}
  @stop %Stops.Stop{id: "stop-id", name: "Stop Name"}
  @route %Routes.Route{type: 3, id: "1"}
  @prediction %Predictions.Prediction{departing?: true, direction_id: 0, status: "On Time", trip: @trip}
  @schedule %Schedules.Schedule{
    route: @route,
    trip: @trip,
    stop: @stop
  }
  @vehicle %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: @route.id}
  @predicted_schedule %PredictedSchedule{prediction: @prediction, schedule: @schedule}
  @trip_info %TripInfo{
    route: @route,
    vehicle: @vehicle,
    vehicle_stop_name: @stop.name,
    times: [@predicted_schedule],
  }
  @vehicle_tooltip %VehicleTooltip{
    prediction: @prediction,
    vehicle: @vehicle,
    route: @route,
    trip: @trip,
    stop_name: @stop.name
  }

  describe "pretty_date/2" do
    test "it is today when the date given is todays date" do
      assert pretty_date(Util.service_date) == "today"
    end

    test "it abbreviates the month when the date is not today" do
      date = ~D[2017-01-01]
      assert pretty_date(date) == "Jan 1"
    end

    test "it applies custom formatting if provided" do
      date = ~D[2017-01-01]
      assert pretty_date(date, "{Mfull} {D}, {YYYY}") == "January 1, 2017"
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
        origin: %{name: "Name"},
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
        origin: %{name: "Name"},
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
    test "make sure page reflects information from full_status function", %{conn: conn} do
      route = %Routes.Route{type: 2}
      trip_info = %TripInfo{
        route: route,
        vehicle: %Vehicles.Vehicle{status: :incoming},
        vehicle_stop_name: "Readville"
      }
      actual = Site.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info,
        origin: nil,
        destination: nil,
        direction_id: 0,
        conn: conn,
        route: route
      )
      expected = TripInfo.full_status(trip_info) |> IO.iodata_to_binary
      assert safe_to_string(actual) =~ expected
    end

    test "the fare link has the same origin and destination params as the page", %{conn: conn} do
      origin = %Stop{id: "place-north"}
      destination = %Stop{id: "Fitchburg"}
      route = %Routes.Route{type: 2}
      trip_info = %TripInfo{route: route}

      actual = Site.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info,
        origin: origin,
        destination: destination,
        direction_id: 0,
        route: route,
        conn: conn
      )
      assert safe_to_string(actual) =~ "/fares/commuter_rail?destination=Fitchburg&amp;origin=place-north"
    end
  end

  describe "render_trip_info_stops" do
    @assigns %{
      direction_id: 0,
      route: @route,
      conn: %Plug.Conn{},
      vehicle_tooltips: %{{@trip.id, @stop.id} => @vehicle_tooltip},
      trip_info: @trip_info,
      all_alerts: [%Alerts.Alert{informed_entity: [%Alerts.InformedEntity{
        route: @route.id,
        direction_id: 0,
        stop: @stop.id
      }]}]
    }

    test "real time icon shown when prediction is available" do
      output =
        [{{@predicted_schedule, false}, 3}]
        |> Site.ScheduleV2View.render_trip_info_stops(@assigns, false)
        |> List.first
        |> safe_to_string
      assert output =~ "rss"
    end

    test "Alert icon is shown when alerts are not empty" do
      output =
        [{{@predicted_schedule, false}, 3}]
        |> Site.ScheduleV2View.render_trip_info_stops(@assigns, false)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert output =~ "icon-alert"
    end

    test "Alert icon is shown with tooltip attributes" do
      output =
        [{{@predicted_schedule, false}, 3}]
        |> Site.ScheduleV2View.render_trip_info_stops(@assigns, false)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary
      assert [alert] = output |> IO.iodata_to_binary() |> Floki.find(".icon-alert")
      assert Floki.attribute(alert, "data-toggle") == ["tooltip"]
      assert Floki.attribute(alert, "title") == ["Service alert or delay"]
    end

    test "shows vehicle icon when vehicle location is available" do
      output =
        [{{@predicted_schedule, false}, 2}]
        |> Site.ScheduleV2View.render_trip_info_stops(@assigns, false)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert [_vehicle] = output |> IO.iodata_to_binary() |> Floki.find(".vehicle-bubble")
    end

    test "shows dotted line for last stop when collapsed_stops? is true" do
      html =
        [{{@predicted_schedule, false}, 0}]
        |> Site.ScheduleV2View.render_trip_info_stops(@assigns, true)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert Enum.count(Floki.find(html, ".route-branch-stop-bubble.stop.dotted")) == 1
    end

    test "does not show dotted line for last stop when collapsed_stop? is false" do
      html =
        [{{@predicted_schedule, false}, 0}]
        |> Site.ScheduleV2View.render_trip_info_stops(@assigns, false)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert Enum.count(Floki.find(html, ".route-branch-stop-bubble.stop.dotted")) == 0
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
              all_stops: [{[{nil, :terminus}], %RouteStop{id: "stop 1", name: "Stop 1"}},
                          {[{nil, :terminus}], %RouteStop{id: "stop 2", name: "Stop 2"}}],
              route_shapes: [@shape, @shape],
              active_shape: @shape,
              expanded: nil,
              show_variant_selector: true,
              map_img_src: nil,
              hours_of_operation: @hours_of_operation,
              holidays: [],
              branches: [%Stops.RouteStops{branch: nil, stops: [%RouteStop{id: "stop 1", name: "Stop 1"},
                                                                %RouteStop{id: "stop 2", name: "Stop 2"}]}],
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
              all_stops: [{[{nil, :terminus}], %RouteStop{id: "stop 1", branch: nil, name: "Stop 1"}},
                          {[{nil, :terminus}], %RouteStop{id: "stop 2", branch: nil, name: "Stop 2"}}],
              route_shapes: [@shape],
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

    test "does not crash if hours of operation isn't set", %{conn: conn} do
      output = Site.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [],
              route_shapes: [],
              expanded: nil,
              active_shape: nil,
              map_img_src: nil,
              holidays: [],
              branches: [],
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              destination: nil,
              origin: nil,
              direction_id: 1,
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})
      refute safe_to_string(output) =~ "Hours of Operation"
    end

    test "Displays error message when there are no trips in selected direction", %{conn: conn} do
      output = Site.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [],
              route_shapes: [],
              expanded: nil,
              active_shape: nil,
              map_img_src: nil,
              holidays: [],
              branches: [],
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              destination: nil,
              origin: nil,
              direction_id: 1,
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})
      assert safe_to_string(output) =~ "There are no scheduled"
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

  describe "display_departure_range/1" do
    test "with no times, returns No Service" do
      result = display_departure_range(%Departures{first_departure: nil, last_departure: nil})
      assert result == "No Service"
    end

    test "with times, displays them formatted" do
      result = %Departures{
        first_departure: ~N[2017-02-27 06:15:00],
        last_departure: ~N[2017-02-28 01:04:00]
      }
      |> display_departure_range
      |> IO.iodata_to_binary

      assert result == "06:15A-01:04A"
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

    test "Does not list date if none is given", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      rendered = Site.ScheduleV2View.render("_empty.html",
                                            error: nil,
                                            origin: nil,
                                            destination: nil,
                                            direction: "inbound",
                                            date: nil,
                                            conn: conn)
      refute safe_to_string(rendered) =~ "on"
      assert safe_to_string(rendered) =~ "There are no scheduled inbound"
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
      stop = %RouteStop{id: "stop", branch: nil}
      branches = [%Stops.RouteStops{branch: nil, stops: [%RouteStop{id: "stop"}]}]
      assert add_expand_link?(stop, %{branches: branches, expanded: nil, direction_id: 0}) == false
    end

    test "returns false for Kingston" do
      assert add_expand_link?(%RouteStop{}, %{route: %Routes.Route{id: "CR-Kingston"}}) == false
    end

    test "returns true for the first branched stop on non-green lines" do
      stop = %RouteStop{id: "stop", branch: "branch"}
      branches = [
        %RouteStops{branch: nil, stops: []},
        %RouteStops{branch: "branch", stops: [stop]},
        %RouteStops{branch: "other", stops: [%Stops.RouteStop{}]}
      ]
      assert add_expand_link?(stop, %{branches: branches, expanded: nil, direction_id: nil}) == true
    end

    test "returns true on the first branched stop of expanded branch for green line when direction is 0" do
      stop = %RouteStop{id: "place-smary", branch: "Green-C"}
      assert add_expand_link?(stop, %{branches: [], expanded: "Green-C", direction_id: 0}) == true
    end

    test "returns true on terminus of expanded branch for green line when direction is 1" do
      stop = %RouteStop{id: "place-river", branch: "Green-D"}
      assert add_expand_link?(stop, %{branches: [], expanded: "Green-D", direction_id: 1}) == true
    end

    test "returns false for all other branched stops" do
      stop = %RouteStop{id: "place-griggs", branch: "Green-B"}
      branches = [
        %Stops.RouteStops{branch: "Green-B", stops: [%RouteStop{id: "place-bland"}, %RouteStop{id: "place-lake"}]},
        %Stops.RouteStops{branch: "Green-C", stops: [%RouteStop{id: "place-smary"}, %RouteStop{id: "place-clmnl"}]}
      ]
      assert add_expand_link?(stop, %{branches: branches, expanded: nil, direction_id: 0}) == false
    end
  end

  describe "trip_link/4" do
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

  describe "fare_params/2" do
    @origin %Stop{id: "place-north"}
    @destination %Stop{id: "Fitchburg"}

    test "fare link when no origin/destination chosen" do
      assert fare_params(nil, nil) == %{}
    end

    test "fare link when only origin chosen" do
      assert fare_params(@origin, nil) == %{origin: @origin}
    end

    test "fare link when origin and destination chosen" do
      assert fare_params(@origin, @destination) == %{origin: @origin, destination: @destination}
    end
  end
end
