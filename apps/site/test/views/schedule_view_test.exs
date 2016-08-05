defmodule Site.ScheduleViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Site.ScheduleView

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

  test "reverse_direction_opts reverses direction when the stop exists in the other direction" do
    expected = [trip: "", direction_id: "1", dest: "place-harsq", origin: "place-davis", route: "Red"]
    actual = Site.ScheduleView.reverse_direction_opts("place-harsq", "place-davis", "Red", "1")
    assert Keyword.equal?(expected, actual)
  end

  test "reverse_direction_opts doesn't maintain stops when the stop does not exist in the other direction" do
    expected = [trip: "", direction_id: "1", dest: nil, origin: nil, route: "16"]
    actual = Site.ScheduleView.reverse_direction_opts("111", "2905", "16", "1")
    assert Keyword.equal?(expected, actual)
  end

  describe "newline_to_br/1" do
    test "escapes existing HTML" do
      expected = {:safe, "&lt;br&gt;"}
      actual = ScheduleView.newline_to_br("<br>")

      assert expected == actual
    end

    test "replaces newlines with breaks" do
      expected = {:safe, "hi<br />there"}
      actual = ScheduleView.newline_to_br("hi\nthere")

      assert expected == actual
    end

    test "combines multiple newlines" do
      expected = {:safe, "hi<br />there"}
      actual = ScheduleView.newline_to_br("hi\n\n\nthere")

      assert expected == actual
    end

    test "combines multiple Windows newlines" do
      expected = {:safe, "hi<br />there"}
      actual = ScheduleView.newline_to_br("hi\r\n\r\nthere")

      assert expected == actual
    end

    test "<strong>ifies a header" do
      expected = {:safe, "hi<hr><strong>Header:</strong><br />7:30"}
      actual = ScheduleView.newline_to_br("hi\nHeader:\n7:30")

      assert expected == actual
    end

    test "<strong>ifies a starting long header" do
      expected = {:safe, "<strong>Long Header:</strong><br />7:30"}
      actual = ScheduleView.newline_to_br("Long Header:\n7:30")

      assert expected == actual
    end
  end
end
