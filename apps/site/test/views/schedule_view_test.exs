defmodule Site.ScheduleViewTest do
  @moduledoc false
  use Site.ConnCase, async: true
  alias Site.ScheduleView
  import Phoenix.HTML.Tag, only: [tag: 2]

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

  test "translates the type number to a string" do
    assert ScheduleView.header_text(0, "test route") == "test route"
    assert ScheduleView.header_text(3, "2") == "Route 2"
    assert ScheduleView.header_text(1, "Red Line") == "Red Line"
    assert ScheduleView.header_text(2, "Fitchburg Line") == "Fitchburg"
  end

  describe "map_icon_link/1" do
    test "generates a station link on a map icon" do
      stop = %Schedules.Stop{id: "place-sstat"}
      assert Phoenix.HTML.safe_to_string(ScheduleView.map_icon_link(stop)) ==
        "<a href=\"/stations/place-sstat\"><i class=\"fa fa-map-o\" aria-hidden=true></i></a>"
    end

    test "generates an empty string for other stops" do
      stop = %Schedules.Stop{id: "Boat-Long"}
      assert Phoenix.HTML.safe_to_string(ScheduleView.map_icon_link(stop)) == ""
    end
  end
end
