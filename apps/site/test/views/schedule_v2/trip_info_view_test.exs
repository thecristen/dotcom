defmodule Site.ScheduleV2.TripInfoViewTest do
  use ExUnit.Case, async: true
  alias Routes.Route
  alias Schedules.Schedule
  import Site.ScheduleV2.TripInfoView

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
end
