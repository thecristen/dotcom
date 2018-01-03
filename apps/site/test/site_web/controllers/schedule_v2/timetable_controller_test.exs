defmodule SiteWeb.ScheduleV2Controller.TimetableControllerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import SiteWeb.ScheduleV2Controller.TimetableController
  alias Stops.Stop
  alias Schedules.{Schedule, Trip}

  @stops [
    %Stop{id: "1"},
    %Stop{id: "2"},
    %Stop{id: "3"}
  ]
  @schedules [
    %Schedule{
      time: DateTime.from_unix!(500),
      stop: %Stop{id: "1"},
      trip: %Trip{id: "trip-1", name: "123"}
    },
    %Schedule{
      time: DateTime.from_unix!(5000),
      stop: %Stop{id: "2"},
      trip: %Trip{id: "trip-2", name: "456"}
    },
    %Schedule{
      time: DateTime.from_unix!(50_000),
      stop: %Stop{id: "3"},
      trip: %Trip{id: "trip-3", name: "789"}
    }
  ]

  describe "build_timetable/2" do
    test "trip_schedules: a map from trip_id/stop_id to a schedule" do
      %{trip_schedules: trip_schedules} = build_timetable(@stops, @schedules)

      for schedule <- @schedules do
        assert trip_schedules[{schedule.trip.id, schedule.stop.id}] == schedule
      end

      assert map_size(trip_schedules) == length(@schedules)
    end

    test "all_stops: list of the stops in the same order" do
      %{all_stops: all_stops} = build_timetable(@stops, @schedules)

      assert all_stops == @stops
    end

    test "all_stops: if a stop isn't used, it's removed from the list" do
      schedules = Enum.take(@schedules, 1)

      %{all_stops: all_stops} = build_timetable(@stops, schedules)
      # other two stops were removed
      assert [%{id: "1"}] = all_stops
    end
  end
end
