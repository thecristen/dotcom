defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip, Stop}
  alias Site.Components.Icons.SvgIcon
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
      assert str =~ safe_to_string(svg_icon(%SvgIcon{icon: :map}))
      assert str =~ "View stop information for South Station"
    end

    test "generates a stop link on a map icon for a bus stop that is not a station" do
      str =  %Stop{id: "1736"}
             |> stop_info_link()
             |> safe_to_string()
      assert str =~ stop_path(Site.Endpoint, :show, "1736")
      assert str =~ safe_to_string(svg_icon(%SvgIcon{icon: :map}))
      assert str =~ "View stop information for Blue Hill Ave opp Health Ctr"
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
        [%Schedules.Schedule{route: route, trip: trip, stop: %Stop{id: "stop"}}],
        [],
        "stop",
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

    test "given a vehicle and a route, returns the icon for the route" do
      rendered = safe_to_string(stop_bubble_location_display(true, 1, false))
      assert rendered =~ "icon-subway"
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

  describe "display_train_number/1" do
    test "returns the train number of a schedule" do
      assert display_train_number({%Schedules.Schedule{trip: %Trip{name: "500"}}, nil}) == "500"
    end
  end
end
