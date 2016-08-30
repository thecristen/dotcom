defmodule Site.ScheduleViewTest do
  @moduledoc false
  use Site.ConnCase, async: true
  alias Site.ScheduleView
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Phoenix.HTML.Tag, only: [tag: 2]
  import Phoenix.View, only: [render_to_string: 3]
  alias Predictions.Prediction

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

  describe "reverse_direction_opts/4" do
    test "reverses direction when the stop exists in the other direction" do
      expected = [trip: nil, direction_id: "1", dest: "place-harsq", origin: "place-davis", route: "Red"]
      actual = ScheduleView.reverse_direction_opts("place-harsq", "place-davis", "Red", "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end

    test "doesn't maintain stops when the stop does not exist in the other direction" do
      expected = [trip: nil, direction_id: "1", dest: nil, origin: nil, route: "16"]
      actual = ScheduleView.reverse_direction_opts("111", "2905", "16", "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end
  end

  describe "update_url/2" do
    test "adds additional parameters to a conn", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route"}}

      actual = ScheduleView.update_url(conn, trip: "trip")
      expected = schedule_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "updates existing parameters in a conn", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "old"}}

      actual = ScheduleView.update_url(conn, trip: "trip")
      expected = schedule_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "setting a value to nil removes it from the URL", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "trip"}}

      actual = ScheduleView.update_url(conn, trip: nil)
      expected = schedule_path(conn, :show, "route")

      assert expected == actual
    end

    test 'setting a value to "" keeps it from the URL', %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "trip"}}

      actual = ScheduleView.update_url(conn, trip: "")
      expected = schedule_path(conn, :show, "route", trip: "")

      assert expected == actual
    end
end

  describe "hidden_query_params/2" do
    test "creates a hidden tag for each query parameter", %{conn: conn} do
      actual = %{conn | query_params: %{"one" => "value", "two" => "other"}}
      |> ScheduleView.hidden_query_params

      expected = [tag(:input, type: "hidden", name: "one", value: "value"),
                  tag(:input, type: "hidden", name: "two", value: "other")]

      assert expected == actual
    end
  end

  describe "header_text/2" do
    test "translates the type number to a string" do
      assert ScheduleView.header_text(0, "test route") == "test route"
      assert ScheduleView.header_text(3, "2") == "Route 2"
      assert ScheduleView.header_text(1, "Red Line") == "Red Line"
      assert ScheduleView.header_text(2, "Fitchburg Line") == "Fitchburg"
    end
  end

  describe "with predictions" do
    test "on commuter rail, renders inline predictions", %{conn: conn} do
      conn = get conn, "/schedules/CR-Lowell"
      second_schedule = Enum.at(conn.assigns[:schedules], 1)
      conn = conn
      |> assign(:predictions, [
            %Prediction{
              trip_id: second_schedule.trip.id,
              stop_id: second_schedule.stop.id,
              route_id: second_schedule.route.id,
              direction_id: second_schedule.trip.direction_id,
              time: Util.now,
              status: "All Aboard",
              track: "6"
            }
          ])
      conn = assign(conn, :conn, conn)

      html = render_to_string(Site.ScheduleView, "index.html", conn.assigns)

      assert html =~ "Predicted Departure"
      assert html =~ "Departed" # for the first schedule
      assert html =~ ~R(All Aboard\s+on track&nbsp;6)
    end

    test "for subway, renders a list of times", %{conn: conn} do
      conn = get conn, "/schedules/Red"
      schedule = List.first(conn.assigns[:schedules])
      time = Util.now |> Timex.shift(minutes: 5, seconds: 30)
      conn = conn
      |> assign(:predictions, [
            %Prediction{
              trip_id: schedule.trip.id,
              stop_id: schedule.stop.id,
              route_id: schedule.route.id,
              direction_id: schedule.trip.direction_id,
              time: time
            }
          ])
      conn = assign(conn, :conn, conn)

      html = render_to_string(Site.ScheduleView, "index.html", conn.assigns)

      assert html =~ "Upcoming departures"
      assert html =~ Timex.format!(time, "{kitchen}")
      assert html =~ "5 minutes"
    end
  end

  describe "station_info_link/1" do
    test "generates a station link on a map icon when the stop has station information" do
      stop = %Schedules.Stop{id: "place-sstat"}
      str = safe_to_string(ScheduleView.station_info_link(stop))
      assert str =~ station_path(Site.Endpoint, :show, "place-sstat")
      assert str =~ safe_to_string(Site.ViewHelpers.fa("map-o"))
      assert str =~ "View station information for South Station"
    end

    test "generates an empty string for other stops" do
      stop = %Schedules.Stop{id: "Boat-Long"}
      assert safe_to_string(ScheduleView.station_info_link(stop)) == ""
    end
  end

  describe "trip/3" do
    @stops [%Schedules.Stop{id: "1"},
      %Schedules.Stop{id: "2"},
      %Schedules.Stop{id: "3"},
      %Schedules.Stop{id: "4"},
      %Schedules.Stop{id: "5"}]
    @schedules Enum.map(@stops, fn(stop) -> %Schedules.Schedule{stop: stop, trip: @trip, route: @route} end)

    test "filters a list of schedules down to a list representing a trip starting at from and going until to" do
      start_id = "2"
      end_id = "4"

      trip = ScheduleView.trip(@schedules, start_id, end_id)
      assert length(trip) == 3
      assert Enum.at(trip, 0).stop.id == "2"
      assert Enum.at(trip, 2).stop.id == "4"
    end

    test "when end id is nil, trip goes until the end of the line" do
      start_id = "2"
      end_id = nil

      trip = ScheduleView.trip(@schedules, start_id, end_id)
      assert length(trip) == 4
      assert Enum.at(trip, 0).stop.id == "2"
      assert Enum.at(trip, 3).stop.id == "5"
    end
  end

  describe "schedule_list/2" do
    @stops [%Schedules.Stop{id: "1"},
      %Schedules.Stop{id: "2"},
      %Schedules.Stop{id: "3"},
      %Schedules.Stop{id: "4"},
      %Schedules.Stop{id: "5"},
      %Schedules.Stop{id: "6"},
      %Schedules.Stop{id: "7"},
      %Schedules.Stop{id: "8"},
      %Schedules.Stop{id: "9"},
      %Schedules.Stop{id: "10"},
      %Schedules.Stop{id: "11"},
      %Schedules.Stop{id: "12"}]
    @schedules Enum.map(@stops, fn(stop) -> %Schedules.Schedule{stop: stop, trip: @trip, route: @route} end)

    test "when all times is false, filters a list of schedules to the first 9" do
      assert length(ScheduleView.schedule_list(@schedules, false)) == 9
    end

    test "when all times is true, does not filter the list" do
      assert length(ScheduleView.schedule_list(@schedules, true)) == length(@schedules)
    end

  end
end
