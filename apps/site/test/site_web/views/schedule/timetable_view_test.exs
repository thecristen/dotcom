defmodule SiteWeb.Schedule.TimetableViewTest do
  use ExUnit.Case, async: true
  import SiteWeb.ScheduleView.Timetable
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Phoenix.HTML, only: [safe_to_string: 1]

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

    test "does not render the earlier/later train columns when there is one schedule", %{assigns: assigns} do
      trip = %Schedules.Trip{name: "name"}
      header_schedules = [
        %Schedules.Schedule{trip: trip}
      ]
      assigns = Keyword.put(assigns, :header_schedules, header_schedules)
      rendered = SiteWeb.ScheduleView.render("_timetable.html", assigns)
      refute safe_to_string(rendered) =~ "Earlier Trains"
      refute safe_to_string(rendered) =~ "Later Trains"
    end

    test "renders the earlier/later train columns when there are two or more schedules", %{assigns: assigns} do
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
