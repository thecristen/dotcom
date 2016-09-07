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
    actual = ScheduleView.reverse_direction_opts("place-harsq", "place-davis", "Red", "1")
    assert Keyword.equal?(expected, actual)
  end

  test "reverse_direction_opts doesn't maintain stops when the stop does not exist in the other direction" do
    expected = [trip: "", direction_id: "1", dest: nil, origin: nil, route: "16"]
    actual = ScheduleView.reverse_direction_opts("111", "2905", "16", "1")
    assert Keyword.equal?(expected, actual)
  end
end
