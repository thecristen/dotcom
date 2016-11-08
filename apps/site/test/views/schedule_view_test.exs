defmodule Site.ScheduleViewTest do
  @moduledoc false
  use Site.ConnCase, async: true
  alias Site.ScheduleView
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Phoenix.View, only: [render_to_string: 3]
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.{Schedule, Stop, Trip}

  @stop %Stop{id: "stop_id"}
  @trip %Trip{id: "trip_id"}
  @route %Route{type: 2, id: "route_id"}
  @schedule %Schedule{stop: @stop, trip: @trip, route: @route}

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

  describe "update_schedule_url/2" do
    test "adds additional parameters to a conn", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route"}}

      actual = ScheduleView.update_schedule_url(conn, trip: "trip")
      expected = schedule_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "updates existing parameters in a conn", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "old"}}

      actual = ScheduleView.update_schedule_url(conn, trip: "trip")
      expected = schedule_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "setting a value to nil removes it from the URL", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "trip"}}

      actual = ScheduleView.update_schedule_url(conn, trip: nil)
      expected = schedule_path(conn, :show, "route")

      assert expected == actual
    end

    test 'setting a value to "" keeps it from the URL', %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "trip"}}

      actual = ScheduleView.update_schedule_url(conn, trip: "")
      expected = schedule_path(conn, :show, "route", trip: "")

      assert expected == actual
    end
  end

  describe "with predictions" do
    setup %{conn: conn} do
      conn = conn
      |> Plug.Test.put_req_cookie("predictions", "true")
      {:ok, %{conn: conn}}
    end

    test "on commuter rail, renders inline predictions", %{conn: conn} do
      conn = get conn, "/schedules/CR-Lowell?direction_id=0"
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

      assert html =~ "Upcoming Departures"
      assert html =~ Timex.format!(time, "{kitchen}")
    end
  end

  describe "stop_info_link/1" do
    test "generates a stop link on a map icon when the stop has stop information" do
      stop = %Stop{id: "place-sstat"}
      str = safe_to_string(ScheduleView.stop_info_link(stop))
      assert str =~ stop_path(Site.Endpoint, :show, "place-sstat")
      assert str =~ safe_to_string(Site.ViewHelpers.fa("map-o"))
      assert str =~ "View stop information for South Station"
    end
  end

  describe "trip/3" do
    @stops [%Stop{id: "1"},
      %Stop{id: "2"},
      %Stop{id: "3"},
      %Stop{id: "4"},
      %Stop{id: "5"}]
    @schedules Enum.map(@stops, fn(stop) -> %Schedule{stop: stop, trip: @trip, route: @route} end)

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
    @stops [%Stop{id: "1"},
      %Stop{id: "2"},
      %Stop{id: "3"},
      %Stop{id: "4"},
      %Stop{id: "5"},
      %Stop{id: "6"},
      %Stop{id: "7"},
      %Stop{id: "8"},
      %Stop{id: "9"},
      %Stop{id: "10"},
      %Stop{id: "11"},
      %Stop{id: "12"}]
    @schedules Enum.map(@stops, fn(stop) -> %Schedule{stop: stop, trip: @trip, route: @route} end)

    test "when all times is false, and number of schedules is more than the limit, only return initial schedules " do
      many_schedules = Stream.cycle(@schedules) |> Enum.take(ScheduleView.schedule_display_limit + 1)
      assert length(ScheduleView.schedule_list(many_schedules, false)) == ScheduleView.schedule_display_initial
    end

    test "when all times is false, and number of schedules is less than the limit, show all times" do
      limited_schedules = Stream.cycle(@schedules) |> Enum.take(ScheduleView.schedule_display_limit - 1)
      assert length(ScheduleView.schedule_list(limited_schedules, false)) == length(limited_schedules)
    end

    test "when all times is true, does not filter the list" do
      assert length(ScheduleView.schedule_list(@schedules, true)) == length(@schedules)
    end
  end

  describe "rendering _prediction.html" do
    @original_time ~N[2016-01-01T00:00:00]
    @estimated_time ~N[2016-01-01T01:00:00]
    @schedule %Schedule{time: @original_time}

    def render_prediction(prediction) do
      render_to_string(ScheduleView, "_prediction.html", prediction: prediction, schedule: @schedule)
    end

    test "renders On Time if the times are the same and there's no status" do
      prediction = %Prediction{time: @original_time}
      response = render_prediction(prediction)

      assert response =~ "On Time"
    end

    test "renders 'Estimated departure: time' if different from scheduled time" do
      prediction = %Prediction{time: @estimated_time}

      response = render_prediction(prediction)

      assert response =~ "Estimated departure: 1:00AM"
    end

    test "if there's no predicted time but there is a status, renders the status" do
      prediction = %Prediction{status: "Departed"}

      response = render_prediction(prediction)

      assert response =~ "Departed"
    end

    test "if the status is Now Boarding or All Aboard, doesn't display a time even if it's different" do
      for status <- ["All Aboard", "Now Boarding"] do
        prediction = %Prediction{time: @estimated_time, track: "5", status: status}
        response = render_prediction(prediction)
        assert response =~ ~r(#{status}\s+on track&nbsp;5)
        refute response =~ "1:00AM"
      end
    end

    test "if there is another status with a different time, renders the status along with the departure" do
      prediction = %Prediction{time: @estimated_time, status: "Delayed"}
      response = render_prediction(prediction)
      assert response =~ "Delayed"
      assert response =~ "(est. departure: 1:00AM)"
    end

    test "doesn't render departure if the status is Departed" do
      prediction = %Prediction{time: @estimated_time, status: "Departed"}
      response = render_prediction(prediction)
      assert response =~ "Departed"
      refute response =~ "est. departure"
    end
  end
end
