defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip, Stop}
  alias Routes.Route
  import Site.ScheduleV2View
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "update_schedule_url/2" do
    test "adds additional parameters to a conn" do
      conn = :get
      |> build_conn(schedule_v2_path(Site.Endpoint, :show, "route"))
      |> fetch_query_params

      actual = update_schedule_url(conn, trip: "trip")
      expected = schedule_v2_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "updates existing parameters in a conn" do
      conn = :get
      |> build_conn(schedule_v2_path(Site.Endpoint, :show, "route", trip: "old"))
      |> fetch_query_params

      actual = update_schedule_url(conn, trip: "trip")
      expected = schedule_v2_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "setting a value to nil removes it from the URL" do
      conn = :get
      |> build_conn(schedule_v2_path(Site.Endpoint, :show, "route", trip: "trip"))
      |> fetch_query_params

      actual = update_schedule_url(conn, trip: nil)
      expected = schedule_v2_path(conn, :show, "route")

      assert expected == actual
    end

    test "setting a value to \"\" keeps it from the URL" do
      conn = :get
      |> build_conn(schedule_v2_path(Site.Endpoint, :show, "route", trip: "trip"))
      |> fetch_query_params

      actual = update_schedule_url(conn, trip: "")
      expected = schedule_v2_path(conn, :show, "route", trip: "")

      assert expected == actual
    end
  end

  describe "stop_info_link/1" do
    test "generates a stop link on a map icon when the stop has stop information" do
      str = %Stop{id: "place-sstat"}
            |> stop_info_link()
            |> safe_to_string()
      assert str =~ stop_path(Site.Endpoint, :show, "place-sstat")
      assert str =~ safe_to_string(svg_icon(%Site.Components.Icons.SvgIcon{icon: :map}))
      assert str =~ "View stop information for South Station"
    end

    test "generates a stop link on a map icon for a bus stop that is not a station" do
      str =  %Stop{id: "1736"}
             |> stop_info_link()
             |> safe_to_string()
      assert str =~ stop_path(Site.Endpoint, :show, "1736")
      assert str =~ safe_to_string(svg_icon(%Site.Components.Icons.SvgIcon{icon: :map}))
      assert str =~ "View stop information for Blue Hill Ave opp Health Ctr"
    end
  end

  describe "Shifting months" do
    test "Months are not skipped when shifting" do
      date = ~D[2016-02-28]
      assert add_month(date).month == 3
      assert decrement_month(date).month == 1
    end
    test "Years are incremented on when shifting to new year" do
      date = ~D[2016-12-31]
      shifted_date = add_month(date)
      assert shifted_date.month == 1
      assert shifted_date.year == 2017
    end
  end

  describe "previous_month_class/1" do
    test "disables the link if the given date is in the current month" do
      assert previous_month_class(Util.today) == " disabled"
    end

    test "disables the link if the given date is in a previous month" do
      assert Util.today |> Timex.shift(months: -2) |> previous_month_class == " disabled"
    end

    test "leaves the link enabled if the given date is in a future month" do
      assert Util.today |> Timex.shift(months: 2) |> previous_month_class == ""
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
      assert display_direction([]) == ""
    end

    test "given a non-empty list of schedules, displays the direction of the first schedule's route" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}}
      trip = %Trip{direction_id: 1}
      schedules = [
        %Schedules.Schedule{route: route, trip: trip}
      ]
      assert schedules |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end

  describe "merge_predictions_and_schedules/2" do
    test "deduplicates departures by trip ID" do
      now = Util.now
      predictions = for trip_id <- 0..4 do
        %Prediction{time: now, trip: %Trip{id: trip_id}}
      end
      schedules = for trip_id <- 3..6 do
        %Schedule{time: now, trip: %Trip{id: trip_id}}
      end
      merged = merge_predictions_and_schedules(predictions, schedules)
      assert merged |> Enum.uniq_by(& &1.trip.id) == merged
    end

    test "sorts departures by time" do
      now = Util.now
      predictions = for offset <- 0..2 do
        %Prediction{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      schedules = for offset <- 3..5 do
        %Schedule{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      merged = merge_predictions_and_schedules(predictions, schedules)
      assert merged |> Enum.sort_by(& &1.time) == merged
    end

    test "with no predictions, shows all schedules" do
      now = Util.now
      schedules = for trip_id <- 0..5 do
        %Schedule{time: now, trip: %Trip{id: trip_id}}
      end
      merged = merge_predictions_and_schedules([], schedules)
      assert merged == schedules
    end

    test "shows predicted departures first, then scheduled departures" do
      now = Util.now
      predictions = for offset <- [1, 3] do
        %Prediction{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      schedules = for offset <- [0, 2, 4] do
        %Schedule{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      merged = merge_predictions_and_schedules(predictions, schedules)
      assert merged == List.flatten [predictions, List.last(schedules)]
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

  describe "group_trips/4" do
    @schedule_time Timex.now
    @prediction_time Timex.shift(@schedule_time, hours: 1)
    @origin "origin"
    @dest "dest"

    @trip1 %Trip{id: 1}
    @trip2 %Trip{id: 2}
    @trip3 %Trip{id: 3}
    @trip4 %Trip{id: 4}

    @schedule_pair1 {%Schedule{trip: @trip1, time: @schedule_time}, %Schedule{trip: @trip1, time: @prediction_time}}
    @schedule_pair2 {%Schedule{trip: @trip2, time: @schedule_time}, %Schedule{trip: @trip2, time: @prediction_time}}
    @schedule_pair3 {%Schedule{trip: @trip3, time: @schedule_time}, %Schedule{trip: @trip3, time: @prediction_time}}
    @schedule_pair4 {%Schedule{trip: @trip4, time: @schedule_time}, %Schedule{trip: @trip4, time: @prediction_time}}

    @origin_prediction1 %Prediction{trip: @trip1, stop_id: @origin, time: @prediction_time}
    @dest_prediction1 %Prediction{trip: @trip1, stop_id: @dest, time: @prediction_time}
    @origin_prediction2 %Prediction{trip: @trip2, stop_id: @origin, time: @prediction_time}
    @dest_prediction2 %Prediction{trip: @trip2, stop_id: @dest, time: @prediction_time}
    @dest_prediction4 %Prediction{trip: @trip4, stop_id: @dest, time: @prediction_time}

    test "Predictions are shown if there are no corresponding schedules" do
      trips = group_trips([@schedule_pair3], [@origin_prediction1, @dest_prediction1, @dest_prediction2], @origin, @dest)
      assert Enum.count(trips) == 3
      assert match?({{nil, _prediction}, {nil, _prediction2}}, List.first(trips))
      assert match?({{_departure, nil}, {_arrival, nil}}, List.last(trips))
    end

    test "Predictions are shown first" do
      schedules = [@schedule_pair1, @schedule_pair2, @schedule_pair3]
      predictions = [@origin_prediction1, @dest_prediction1, @dest_prediction2, @origin_prediction2]
      trips = group_trips(schedules, predictions, @origin, @dest)

      predicted_schedules = Enum.take_while(trips, &prediction?/1)
      assert Enum.count(predicted_schedules) == 2
    end

    test "scheduled_predictions are shown in the order: Predicted arrivals without departures, predictions, schedules" do
      schedules = [@schedule_pair2, @schedule_pair3, @schedule_pair4]
      predictions = [@dest_prediction1, @origin_prediction2, @dest_prediction4]
      trips = group_trips(schedules, predictions, @origin, @dest)

      assert {{nil, nil}, {nil, %Prediction{trip: @trip1}}} = Enum.at(trips, 0)
      assert {{%Schedule{trip: @trip2}, %Prediction{trip: @trip2}}, {_arrival, nil}} = Enum.at(trips, 1)
      assert {{%Schedule{trip: @trip4}, nil}, {_arrival, %Prediction{trip: @trip4}}} = Enum.at(trips, 2)
      assert {{%Schedule{trip: @trip3}, nil}, {%Schedule{trip: @trip3}, nil}} = Enum.at(trips, 3)
    end

    test "Predictions are paired by origin and destination" do
      schedules = [@schedule_pair1, @schedule_pair2]
      predictions = [@origin_prediction1, @dest_prediction1, @dest_prediction2, @origin_prediction2]
      trips = group_trips(schedules, predictions, @origin, @dest)

      for {{_departure, departure_prediction}, {_arrival, arrival_prediction}} <- trips do
        assert departure_prediction.stop_id == @origin
        assert arrival_prediction.stop_id == @dest
      end
    end
  end

  describe "get_valid_trip/1" do
    test "Returns a trip id" do
      schedule = %Schedule{trip: %Trip{id: "1"}}
      prediction = %Prediction{trip: %Trip{id: "8"}}

      schedule_pair1 = {{nil, prediction}, {nil, nil}}
      schedule_pair2 = {{nil, nil}, {nil, prediction}}
      schedule_pair3 = {{schedule, nil}, {schedule, nil}}

      assert get_valid_trip(schedule_pair1) == "8"
      assert get_valid_trip(schedule_pair2) == "8"
      assert get_valid_trip(schedule_pair3) == "1"
    end
  end

  describe "all_trips/1" do
    test "limits trips if passed false value" do
      schedule = %Schedule{trip: %Trip{id: 1}}
      many_schedules = List.duplicate(schedule, 50)
      limited_trips = all_trips(many_schedules, false)
      complete_trips = all_trips(many_schedules, true)

      assert Enum.count(limited_trips) < Enum.count(many_schedules)
      assert complete_trips == many_schedules
    end
  end

  test "full_route_name/1 adds \"Bus Route\" to route name for bus routes, does not change other routes" do
    assert full_route_name(%Route{type: 3, name: "1"}) == "Bus Route 1"
    assert full_route_name(%Route{type: 2, name: "Commuter Rail"}) == "Commuter Rail"
    assert full_route_name(%Route{type: 1, name: "Subway"}) == "Subway"
    assert full_route_name(%Route{type: 4, name: "Ferry"}) == "Ferry"
  end

  test "scheduled_duration/1 calculates the time between two stops" do
    schedule_list = [%Schedule{time: Timex.shift(Util.now, minutes: -10)}, %Schedule{time: Timex.shift(Util.now, minutes: 10)}]
    assert scheduled_duration(schedule_list) == "20"
    assert scheduled_duration([]) == ""
  end

  defp prediction?({{_, nil}, {_, nil}}), do: false
  defp prediction?(_), do: true

  describe "stop_bubble_location_display/3" do
    test "given false, returns the empty string" do
      assert stop_bubble_location_display(false, 1, false) == ""
    end

    test "given a vehicle and a route, returns the icon for the route" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, false))
      assert rendered =~ "icon-subway"
      assert rendered =~ "icon-small"
    end

    test "when the last parameter is true, adds the vehicle-terminus class" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, true))
      assert rendered =~ "vehicle-terminus"
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
    |> assign(:all_schedules, Enum.to_list(0..10))
    |> assign(:offset, offset)
    |> link_fn.()
    |> Phoenix.HTML.safe_to_string
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
        icon = svg_icon(%Site.Components.Icons.SvgIcon{icon: :commuter_rail})
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
end
