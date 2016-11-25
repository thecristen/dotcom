defmodule Site.ScheduleController.DirectionNamesTest do
  use Site.ConnCase, async: true

  alias Schedules.{Stop, Schedule}
  import Site.ScheduleController.DirectionNames

  @all_stops [
    %Stop{id: "1", name: "One"},
    %Stop{id: "2", name: "Two"}
  ]

  describe "from/2" do
    test "with paired schedules, uses the first item to find the stop" do
      pairs = [{%Schedule{stop: %{id: "2"}}, %Schedule{stop: %{id: "1"}}}]
      assert from(pairs, @all_stops) == %Stop{id: "2", name: "Two"}
    end

    test "with a list of schedules, returns the most frequent ID" do
      schedules = [
        %Schedule{stop: %{id: "1"}},
        %Schedule{stop: %{id: "2"}},
        %Schedule{stop: %{id: "2"}}
      ]
      assert from(schedules, @all_stops) == %Stop{id: "2", name: "Two"}
    end

    test "without a stop in all_stops, returns a Stop with ID nil" do
      schedules = [
        %Schedule{stop: %{id: "3"}}
      ]
      assert from(schedules, @all_stops) == %Stop{id: nil}
    end
  end
end
