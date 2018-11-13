defmodule SiteWeb.Schedule.TimetableViewTest do
  use ExUnit.Case, async: true
  import SiteWeb.ScheduleView.Timetable
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import VehicleHelpers, only: [build_tooltip_index: 3]

  describe "timetable_location_display/1" do
    test "given nil, returns the empty string" do
      assert timetable_location_display(nil) == ""
    end

    test "otherwise, displays the CR icon" do
      for status <- [:in_transit, :incoming, :stopped] do
        assert %Vehicles.Vehicle{status: status}
               |> timetable_location_display()
               |> safe_to_string() =~ "c-svg__icon-commuter-rail-default"
      end
    end
  end

  describe "timetable_tooltip/4" do
    @locations %{
      {"CR-Weekday-Fall-18-515", "place-sstat"} => %Vehicles.Vehicle{
        latitude: 1.1,
        longitude: 2.2,
        status: :stopped,
        stop_id: "place-sstat",
        trip_id: "CR-Weekday-Fall-18-515",
        shape_id: "903_0018"
      }
    }

    @predictions [
      %Predictions.Prediction{
        departing?: true,
        time: ~N[2018-05-01T11:00:00],
        status: "On Time",
        trip: %Schedules.Trip{id: "CR-Weekday-Fall-18-515", shape_id: "903_0018"},
        stop: %Stops.Stop{id: "place-sstat"}
      }
    ]

    @route %Routes.Route{name: "Framingham/Worcester Line", type: 2}

    @tooltips build_tooltip_index(@route, @locations, @predictions)

    @tooltip_key {"CR-Weekday-Fall-18-515", "place-sstat"}

    @expected_vehicle "Worcester train 515 has arrived at South Station"
    @expected_flag "Flag Stop"
    @expected_delayed "Early Departure Stop"

    test "returns nil when there are no matches" do
      assert nil == timetable_tooltip(%{}, {"a", "b"}, false, false)
    end

    test "returns only a vehicle" do
      actual = timetable_tooltip(@tooltips, @tooltip_key, false, false)
      assert actual =~ @expected_vehicle
      refute actual =~ @expected_flag
      refute actual =~ @expected_delayed
    end

    test "returns only a flag stop" do
      actual = timetable_tooltip(%{}, {"a", "b"}, false, true)
      refute actual =~ @expected_vehicle
      assert actual =~ @expected_flag
      refute actual =~ @expected_delayed
    end

    test "returns only an early departure" do
      actual = timetable_tooltip(%{}, {"a", "b"}, true, false)
      refute actual =~ @expected_vehicle
      refute actual =~ @expected_flag
      assert actual =~ @expected_delayed
    end

    test "returns a vehicle and a flag stop" do
      actual = timetable_tooltip(@tooltips, @tooltip_key, false, true)
      assert actual =~ @expected_vehicle
      assert actual =~ @expected_flag
      refute actual =~ @expected_delayed
    end
  end

  describe "_timetable.html" do
    setup do
      conn = %{build_conn() | query_params: %{}}
      date = ~D[2018-01-01]
      headsigns = %{0 => ["Headsign"]}
      offset = 0
      route = %Routes.Route{}
      direction_id = 0
      origin = destination = nil
      all_alerts = []
      alerts = []
      upcoming_alerts = []

      all_stops = [
        %Stops.Stop{id: "stop", name: "Stop"}
      ]

      vehicle_tooltips = vehicle_locations = trip_messages = trip_schedules = %{}
      show_date_select? = false

      assigns = [
        conn: conn,
        date: date,
        headsigns: headsigns,
        route: route,
        direction_id: direction_id,
        origin: origin,
        destination: destination,
        all_alerts: all_alerts,
        alerts: alerts,
        upcoming_alerts: upcoming_alerts,
        offset: offset,
        show_date_select?: show_date_select?,
        all_stops: all_stops,
        vehicle_tooltips: vehicle_tooltips,
        vehicle_locations: vehicle_locations,
        trip_messages: trip_messages,
        trip_schedules: trip_schedules
      ]

      {:ok, %{assigns: assigns}}
    end

    test "does not render the earlier/later train columns when there is one schedule", %{
      assigns: assigns
    } do
      trip = %Schedules.Trip{name: "name"}

      header_schedules = [
        %Schedules.Schedule{trip: trip}
      ]

      assigns = Keyword.put(assigns, :header_schedules, header_schedules)
      rendered = SiteWeb.ScheduleView.render("_timetable.html", assigns)
      refute safe_to_string(rendered) =~ "Earlier Trains"
      refute safe_to_string(rendered) =~ "Later Trains"
    end

    test "renders the earlier/later train columns when there are two or more schedules", %{
      assigns: assigns
    } do
      trip = %Schedules.Trip{name: "name"}

      header_schedules = [
        %Schedules.Schedule{trip: trip},
        %Schedules.Schedule{trip: trip}
      ]

      assigns = Keyword.put(assigns, :header_schedules, header_schedules)
      rendered = SiteWeb.ScheduleView.render("_timetable.html", assigns)
      assert safe_to_string(rendered) =~ "Earlier Trains"
      assert safe_to_string(rendered) =~ "Later Trains"
    end
  end
end
