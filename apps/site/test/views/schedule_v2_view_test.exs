defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}
  import Site.ScheduleV2View
  import Phoenix.HTML, only: [safe_to_string: 1]

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

    test "given a non-empty list of schedules, displays the direction of the first schedule's route" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}}
      trip = %Trip{direction_id: 1}
      stop_times = StopTimeList.build(
        [%Schedules.Schedule{route: route, trip: trip, stop: %Schedules.Stop{id: "stop"}}],
        [],
        "stop",
        nil,
        :keep_all,
        ~N[2017-01-01T06:30:00]
      )
      assert stop_times |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end

    test "finds later schedules if the first is nil" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}, id: "1"}
      stop = %Schedules.Stop{id: "stop"}
      now = Timex.now
      stop_times = StopTimeList.build(
        [%Schedules.Schedule{route: route, trip: %Trip{direction_id: 1, id: "t2"}, stop: stop, time: now}],
        [%Predictions.Prediction{route: route, stop: stop, trip: %Trip{direction_id: 1, id: "t1"}, time: Timex.shift(now, hours: -1)}],
        stop.id,
        nil,
        :keep_all,
        ~N[2017-01-01T06:30:00]
      )
      assert stop_times |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end

  describe "display_scheduled_prediction/1" do
    @schedule_time Timex.now
    @prediction_time Timex.shift(@schedule_time, hours: 1)

    test "Prediction is used if one is given" do
      display_time = display_scheduled_prediction(%PredictedSchedule{schedule: %Schedule{time: @schedule_time}, prediction: %Prediction{time: @prediction_time}})
      assert safe_to_string(display_time) =~ Site.ViewHelpers.format_schedule_time(@prediction_time)
      assert safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Scheduled time is used if no prediction is available" do
      display_time = display_scheduled_prediction(%PredictedSchedule{schedule: %Schedule{time: @schedule_time}, prediction: nil})
      assert safe_to_string(display_time) =~ Site.ViewHelpers.format_schedule_time(@schedule_time)
      refute safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Empty string returned if no value available in predicted_schedule pair" do
      assert display_scheduled_prediction(%PredictedSchedule{schedule: nil, prediction: nil}) == ""
    end
  end

  describe "stop_bubble_location_display/3" do
    test "when vehicle is not at stop and stop is not a terminus, returns an empty circle" do
      rendered = safe_to_string(stop_bubble_location_display(false, 1, false))
      assert rendered =~ "trip-bubble-open"
      assert rendered =~ "svg"
    end

    test "when vehicle is not at stop and stop is a terminus, returns a filled circle" do
      rendered = safe_to_string(stop_bubble_location_display(false, 1, true))
      assert rendered =~ "trip-bubble-filled"
      assert rendered =~ "svg"
    end

    test "when vehicle is at stop and stop is not a terminus, returns a normal vehicle circle icon" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, false))
      assert rendered =~ "icon-circle"
      assert rendered =~ "icon-boring"
    end

    test "when vehicle is at stop and stop is a terminus, returns an inverse vehicle circle icon" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, true))
      assert rendered =~ "icon-circle"
      assert rendered =~ "icon-inverse"
    end

    test "given a vehicle and the subway route_type, returns the icon for the subway" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, false))
      assert rendered =~ "icon-subway"
    end

    test "given a vehicle and the bus route_type, returns the icon for the bus" do
      rendered = safe_to_string(stop_bubble_location_display(true, 3, false))
      assert rendered =~ "icon-bus"
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

  describe "display_commuter_scheduled_prediction/1" do
    test "if the scheduled and predicted times differ crosses out the scheduled one" do
      now = Util.now
      then = Timex.shift(now, minutes: 5)

      result = %PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: then}}
      |> display_commuter_scheduled_prediction
      |> safe_to_string

      assert result =~ "<del>#{Site.ViewHelpers.format_schedule_time(now)}</del>"
      assert result =~ Site.ViewHelpers.format_schedule_time(then)
      assert result =~ "fa fa-rss"
    end

    test "if the times do not differ, just returns the same result as display_scheduled_prediction/1" do
      now = Util.now
      stop_time = %PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: now}}
      result = display_commuter_scheduled_prediction(stop_time)

      assert result == display_scheduled_prediction(stop_time)
    end

    test "handles nil schedules" do
      stop_time = %PredictedSchedule{schedule: nil, prediction: %Prediction{time: Util.now}}
      result = display_commuter_scheduled_prediction(stop_time)

      assert result == display_scheduled_prediction(stop_time)
    end

    test "handles nil predictions" do
      stop_time = %PredictedSchedule{schedule: %Schedule{time: Util.now}, prediction: nil}
      result = display_commuter_scheduled_prediction(stop_time)

      assert result == display_scheduled_prediction(stop_time)
    end
  end

  describe "Schedule Alerts" do
    @schedule %Schedule{trip: %Trip{id: "trip"}, stop: %Schedules.Stop{id: "stop"}}
    @prediction %Prediction{trip: %Trip{id: "trip_pred"}, stop: %Schedules.Stop{id: "stop_pred"}}
    @route %Routes.Route{type: 1, id: "1"}

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
        alert = List.first(trip_alerts(%PredictedSchedule{schedule: @schedule, prediction: @prediction}, @alerts, @route, 1))
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
        alerts = trip_alerts(%PredictedSchedule{schedule: @schedule, prediction: @prediction}, @alerts, %Routes.Route{type: 3, id: "1"}, 1)
        assert alerts == []
      end

      test "stop alerts use schedule for match" do
        alert = List.first(stop_alerts(%PredictedSchedule{schedule: @schedule, prediction: @prediction}, @alerts, "1", 1))
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

  describe "_trip_info_row.html" do
    @output Site.ScheduleV2View.render(
            "_trip_info_row.html",
            name: "name",
            href: "",
            vehicle?: true,
            terminus?: true,
            alerts: ["alert"],
            predicted_schedule: %PredictedSchedule{prediction: @prediction, schedule: @schedule},
            route: %Routes.Route{id: "1", type: 3})

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

  describe "prediction_for_vehicle_location/2" do
    test "when there are no predictions matching the stop and trip returns nil", %{conn: conn} do
      conn = conn
      |> assign(:vehicle_predictions, [])

      assert Site.ScheduleV2View.prediction_for_vehicle_location(conn, "place-sstat", "1234") == nil
    end

    test "when there is a prediction for the stop and trip, returns that prediction", %{conn: conn} do
      prediction = %Predictions.Prediction{stop: %Schedules.Stop{id: "place-sstat"}, trip: %Schedules.Trip{id: "1234"}, status: "Now Boarding", track: 4}
      conn = conn
      |> assign(:vehicle_predictions, [prediction])

      assert Site.ScheduleV2View.prediction_for_vehicle_location(conn, "place-sstat", "1234") == prediction
    end
  end

  describe "prediction_time_text/1" do
    test "when there is no prediction, there is no prediction time" do
      assert Site.ScheduleV2View.prediction_time_text(nil) == ""
    end

    test "when a prediction has a time, gives the arrival time" do
      time = ~N[2017-01-01T13:00:00]
      prediction = %Predictions.Prediction{time: time}
      result = prediction
      |> Site.ScheduleV2View.prediction_time_text
      |> IO.iodata_to_binary

      assert result == "Arrival: 1:00 PM"
    end

    test "when a prediction is departing, gives the departing time" do
      time = ~N[2017-01-01T12:00:00]
      prediction = %Predictions.Prediction{time: time, departing?: true}
      result = prediction
      |> Site.ScheduleV2View.prediction_time_text
      |> IO.iodata_to_binary

      assert result == "Departure: 12:00 PM"
    end

    test "when a prediction does not have a time, gives nothing" do
      prediction = %Predictions.Prediction{time: nil}
      assert Site.ScheduleV2View.prediction_time_text(prediction) == ""
    end
  end

  describe "prediction_status_text/1" do
    test "when a prediction has a track, gives the time, the status and the track" do
      prediction = %Predictions.Prediction{status: "Now Boarding", track: "4"}
      result = prediction
               |> Site.ScheduleV2View.prediction_status_text
               |> IO.iodata_to_binary

      assert result == "Now boarding on track 4"
    end

    test "when a prediction does not have a track, gives nothing" do
      prediction = %Predictions.Prediction{status: "Now Boarding", track: nil}
      assert Site.ScheduleV2View.prediction_status_text(prediction) == ""
    end
  end

  describe "build_prediction_tooltip/2" do
    test "when there is no time or status for the prediction, returns stop name" do
      assert build_prediction_tooltip("", "", "stop") =~ "stop"
    end

    test "when there is a time but no status for the prediction, gives a tooltip with arrival time" do
      assert build_prediction_tooltip("time", "", "stop") =~ "time"
    end

    test "when there is a status but no time for the prediction, gives a tooltip with the status" do
      assert build_prediction_tooltip("", "now boarding", "stop") =~ "now boarding"
    end

    test "when there is a status and a time for the prediction, gives a tooltip with both and also replaces double quotes with single quotes" do
      test_tooltip = Phoenix.HTML.Tag.content_tag :div do [
        Phoenix.HTML.Tag.content_tag(:p, "stop", class: 'prediction-tooltip'),
        Phoenix.HTML.Tag.content_tag(:p, "time", class: 'prediction-tooltip'),
        Phoenix.HTML.Tag.content_tag(:p, "now boarding", class: 'prediction-tooltip')
      ]
      end
      |> Phoenix.HTML.safe_to_string
      |> String.replace(~s("), ~s('))

      assert build_prediction_tooltip("time", "now boarding", "stop") == test_tooltip
    end
  end

  describe "prediction_tooltip/1" do
    test "creates a tooltip for the prediction" do
      time = ~N[2017-02-17T05:46:28]
      formatted_time = Timex.format!(time, "{h12}:{m} {AM}")
      prediction = %Predictions.Prediction{time: time, status: "Now Boarding", track: "4"}
      result = prediction
               |> Site.ScheduleV2View.prediction_tooltip("stop", nil)
               |> IO.iodata_to_binary

      assert result =~ "Now boarding on track 4"
      assert result =~ "Arrival: #{formatted_time}"
    end

    test "Displays text based on vehicle status" do
      prediction = %Predictions.Prediction{status: "Now Boarding", track: "4"}
      result1 = Site.ScheduleV2View.prediction_tooltip(prediction, "stop", %Vehicles.Vehicle{status: :incoming})
      result2 = Site.ScheduleV2View.prediction_tooltip(prediction, "stop", %Vehicles.Vehicle{status: :stopped})
      result3 = Site.ScheduleV2View.prediction_tooltip(prediction, "stop", %Vehicles.Vehicle{status: :in_transit})

      assert result1 =~ "Train is entering"
      assert result2 =~ "Train has arrived"
      assert result3 =~ "Train has left"
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

  describe "no_stop_times_message/1" do
    test "for subways mentions departures" do
      for type <- [0, 1] do
        result = no_stop_times_message(%Routes.Route{type: type}, Util.service_date())
        assert result == "There are no upcoming departures at this time."
      end
    end

    test "on a date other than the current service date for subways, displays nothing" do
      assert no_stop_times_message(%Routes.Route{type: 1}, Timex.shift(Util.service_date(), weeks: 1)) == ""
    end

    test "for other modes mentions schedules" do
      for type <- [2, 3, 4] do
        result = no_stop_times_message(%Routes.Route{type: type}, ~D[2017-02-23])
        assert result == "There are no scheduled trips at this time."
      end
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
end
