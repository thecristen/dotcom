defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}
  import Site.ScheduleV2View
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "pretty_date/1" do
    test "it is today when the date given is todays date" do
      assert pretty_date(Util.service_date) == "Today"
    end

    test "it abbreviates the month when the date is not today" do
      date = ~D[2017-01-01]
      assert pretty_date(date) == "Jan 1"
    end
  end

  describe "last_departure/1" do
    test "when schedules are a list of schedules, gives the time of the last one" do
      schedules = [%Schedule{time: ~N[2017-01-01T09:30:00]}, %Schedule{time: ~N[2017-01-01T13:30:00]}, %Schedule{time: ~N[2017-01-01T20:30:00]}]
      assert last_departure(schedules) == ~N[2017-01-01T20:30:00]
    end

    test "when schedules are a list of origin destination schedule pairs, gives the time of the last origin" do
      schedules = [{%Schedule{time: ~N[2017-01-01T09:30:00]}, %Schedule{time: ~N[2017-01-01T13:30:00]}},
       {%Schedule{time: ~N[2017-01-01T19:30:00]}, %Schedule{time: ~N[2017-01-01T21:30:00]}}]
      assert last_departure(schedules) == ~N[2017-01-01T19:30:00]
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
        true
      )
      assert stop_times |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end

    test "finds later schedules if the first is nil" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}, id: "1"}
      stop = %Schedules.Stop{id: "stop"}
      now = Timex.now
      stop_times = StopTimeList.build(
        [%Schedules.Schedule{route: route, trip: %Trip{direction_id: 1, id: "t2"}, stop: stop, time: now}],
        [%Predictions.Prediction{route_id: route.id, stop_id: stop.id, trip: %Trip{direction_id: 1, id: "t1"}, time: Timex.shift(now, hours: -1)}],
        stop.id,
        nil,
        true
      )
      assert stop_times |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end

  describe "display_scheduled_prediction/1" do
    @schedule_time Timex.now
    @prediction_time Timex.shift(@schedule_time, hours: 1)

    test "Prediction is used if one is given" do
      display_time = display_scheduled_prediction({%Schedule{time: @schedule_time}, %Prediction{time: @prediction_time}})
      assert safe_to_string(display_time) =~ Site.ViewHelpers.format_schedule_time(@prediction_time)
      assert safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Scheduled time is used if no prediction is available" do
      display_time = display_scheduled_prediction({%Schedule{time: @schedule_time}, nil})
      assert safe_to_string(display_time) =~ Site.ViewHelpers.format_schedule_time(@schedule_time)
      refute safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Empty string returned if no value available in predicted_schedule pair" do
      assert display_scheduled_prediction({nil, nil}) == ""
    end
  end

  describe "stop_bubble_location_display/3" do
    test "given false, returns the empty string" do
      assert stop_bubble_location_display(false, 1, false) == ""
    end

    test "given a vehicle and the subway route_type, returns the icon for the subway" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, false))
      assert rendered =~ "icon-subway"
      assert rendered =~ "icon-small"
    end

    test "given a vehicle and the bus route_type, returns the icon for the bus" do
      rendered = safe_to_string(stop_bubble_location_display(true, 3, false))
      assert rendered =~ "icon-bus"
      assert rendered =~ "icon-small"
    end

    test "when the last parameter is true, adds the vehicle-terminus class" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, true))
      assert rendered =~ "icon-inverse"
    end
  end

  describe "offset_schedules/1" do
    test "drops a number of schedules as assigned in the conn, and takes num_schedules() more", %{conn: conn} do
      assert offset_schedules(0..10, assign(conn, :offset, 2)) == [2, 3, 4, 5, 6, 7]
    end
  end

  defp build_link(offset, link_fn) do
    :get
    |> build_conn("/schedules_v2/CR-Lowell")
    |> fetch_query_params
    |> assign(:header_schedules, Enum.to_list(0..10))
    |> assign(:offset, offset)
    |> link_fn.()
    |> safe_to_string
  end

  describe "earlier_link/1" do
    test "shows a link to update the offset parameter" do
      result = build_link(3, &earlier_link/1)

      assert result =~ "Show earlier times"
      refute result =~ "disabled"
    end

    test "disables the link if the current offset is 0" do
      result = build_link(0, &earlier_link/1)
      assert result =~ "disabled"
      assert result =~ "There are no earlier trips"
    end
  end

  describe "later_link/1" do
    test "shows a link to update the offset parameter" do
      result = build_link(3, &later_link/1)

      assert result =~ "Show later times"
      refute result =~ "disabled"
    end

    test "disables the link if the current offset is greater than the number of schedules minus num_schedules()" do
      result = build_link(7, &later_link/1)
      assert result =~ "disabled"
      assert result =~ "There are no later trips"
    end
  end

  describe "timetable_location_display/1" do
    test "given nil, returns the empty string" do
      assert timetable_location_display(nil) == ""
    end

    test "otherwise, displays the CR icon" do
      for status <- [:in_transit, :incoming, :stopped] do
        icon = svg_icon(%Site.Components.Icons.SvgIcon{icon: :commuter_rail, class: "icon-small"})
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
      frequency_table = [%Schedules.Frequency{time_block: :am_rush}]
      schedules = [%Schedules.Schedule{time: Util.now}]
      date = Util.service_date
      safe_output = Site.ScheduleV2View.render(
        "_frequency.html",
        frequency_table: frequency_table,
        schedules: schedules,
        date: date)
      output = safe_to_string(safe_output)
      assert output =~ "No service between these hours"
    end

    test "renders a headway if the block has service" do
      frequency = %Schedules.Frequency{time_block: :am_rush, min_headway: 5, max_headway: 10}
      frequency_table = [frequency]
      schedules = [%Schedules.Schedule{time: Util.now}]
      date = Util.service_date
      safe_output = Site.ScheduleV2View.render(
        "_frequency.html",
        frequency_table: frequency_table,
        schedules: schedules,
        date: date)
      output = safe_to_string(safe_output)
      assert output =~ TimeGroup.display_frequency_range(frequency)
    end
  end

  describe "display_commuter_scheduled_prediction/1" do
    test "if the scheduled and predicted times differ crosses out the scheduled one" do
      now = Util.now
      then = Timex.shift(now, minutes: 5)

      result = {%Schedule{time: now}, %Prediction{time: then}}
      |> display_commuter_scheduled_prediction
      |> safe_to_string

      assert result =~ "<del>#{Site.ViewHelpers.format_schedule_time(now)}</del>"
      assert result =~ Site.ViewHelpers.format_schedule_time(then)
      assert result =~ "fa fa-rss"
    end

    test "if the times do not differ, just returns the same result as display_scheduled_prediction/1" do
      now = Util.now
      stop_time = {%Schedule{time: now}, %Prediction{time: now}}
      result = display_commuter_scheduled_prediction(stop_time)

      assert result == display_scheduled_prediction(stop_time)
    end

    test "handles nil schedules" do
      stop_time = {nil, %Prediction{time: Util.now}}
      result = display_commuter_scheduled_prediction(stop_time)

      assert result == display_scheduled_prediction(stop_time)
    end

    test "handles nil predictions" do
      stop_time = {%Schedule{time: Util.now}, nil}
      result = display_commuter_scheduled_prediction(stop_time)

      assert result == display_scheduled_prediction(stop_time)
    end
  end

  describe "_trip_info_row.html" do
    test "real time icon shown when prediction is available" do
      time = Util.now
      prediction = %Predictions.Prediction{time: time}
      output = Site.ScheduleV2View.render(
        "_trip_info_row.html",
        prediction: prediction,
        scheduled_time: time,
        name: "name",
        href: "",
        vehicle?: true,
        terminus?: true,
        route: %Routes.Route{id: 1})
      safe_output = safe_to_string(output)
      assert safe_output =~ "rss"
    end
  end
end
