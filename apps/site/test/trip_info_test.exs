defmodule TripInfoTest do
  use ExUnit.Case, async: true
  import TripInfo
  alias TripInfo.Flags

  alias Routes.Route
  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}
  alias Vehicles.Vehicle

  @route %Route{id: "1", name: "1", type: 3}
  @trip %Trip{id: "trip_id"}
  @time_list [
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-01T00:00:00],
      trip: @trip,
      route: @route,
      stop: %Schedules.Stop{id: "place-sstat", name: "South Station"}}},
    %PredictedSchedule{schedule: %Schedule{stop: %Schedules.Stop{id: "skipped during collapse"}}},
    %PredictedSchedule{schedule: %Schedule{stop: %Schedules.Stop{id: "skipped during collapse"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-02T00:00:00],
      trip: @trip,
      route: @route,
      stop: %Schedules.Stop{id: "place-north", name: "North Station"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-02T12:00:00],
      trip: @trip,
      route: @route,
      stop: %Schedules.Stop{id: "place-censq", name: "Central Square"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-02T18:00:00],
      trip: @trip,
      route: @route,
      stop: %Schedules.Stop{id: "place-harsq", name: "Harvard Square"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-03T00:00:00],
      trip: @trip,
      route: @route,
      stop: %Schedules.Stop{id: "place-pktrm", name: "Park Street"}}}]
  @info %TripInfo{
    route: @route,
    origin_id: "place-sstat",
    destination_id: "place-pktrm",
    duration: 60 * 24 * 2, # 2 day duration trip
    sections: [@time_list]}

  describe "from_list/1" do
    test "creates a TripInfo from a list of PredictedSchedules" do
      actual = from_list(@time_list)
      expected = @info
      assert actual == expected
    end

    test "creates a TripInfo with origin/destination even when they are passed in as nil" do
      actual = from_list(@time_list, origin_id: nil, destination_id: nil)
      expected = @info
      assert actual == expected
    end

    test "given an origin, limits the times to just those after origin" do
      actual = from_list(@time_list, origin_id: "place-north")
      first_predicted_schedule = List.first(List.first(actual.sections))
      assert PredictedSchedule.stop(first_predicted_schedule).id == "place-north"
      assert actual.duration == 60 * 24 # 1 day trip
    end

    test "given an origin and destination, limits both sides" do
      actual = from_list(@time_list, origin_id: "place-north", destination_id: "place-censq")
      first = List.first(List.first(actual.sections))
      last = List.last(List.last(actual.sections))
      assert PredictedSchedule.stop(first).id == "place-north"
      assert PredictedSchedule.stop(last).id == "place-censq"
      assert actual.duration == 60 * 12 # 12 hour trip
    end

    test "given an origin/destination/vehicle, does not keep stop before the origin if the vehicle is there" do
      actual = from_list(@time_list, origin_id: "place-censq", destination_id: "place-harsq", vehicle: %Vehicle{stop_id: "place-north"})
      first = List.first(List.first(actual.sections))
      last = List.last(List.last(actual.sections))
      assert PredictedSchedule.stop(first).id == "place-censq"
      assert PredictedSchedule.stop(last).id == "place-harsq"
      assert actual.duration == 60 * 6 # 6 hour trip from censq to harsq
    end

    test "given an origin/destination/vehicle, does not keep stops before the origin if the vehicle is after the origin" do
      actual = from_list(@time_list, origin_id: "place-north", destination_id: "place-harsq", vehicle: %Vehicle{stop_id: "place-censq"})
      first = List.first(List.first(actual.sections))
      last = List.last(List.last(actual.sections))
      assert PredictedSchedule.stop(first).id == "place-north"
      assert PredictedSchedule.stop(last).id == "place-harsq"
      assert actual.duration == 60 * 18
    end

    test "if collapse? is true, shows the origin + 1 after, destination + 1 before" do
      actual = from_list(@time_list, collapse?: true)
      assert actual.sections == [Enum.take(@time_list, 2), Enum.take(@time_list, -2)]
      assert actual.duration == @info.duration
    end

    test "if collapse? is false but there are not enough stops, display them all" do
      actual = from_list(@time_list, origin_id: "place-north", collapse?: true)
      assert actual.sections == [Enum.drop_while(@time_list, & PredictedSchedule.stop(&1).id != "place-north")]
    end

    test "if there are not enough times, returns an error" do
      actual = @time_list |> Enum.take(1) |> from_list
      assert {:error, _} = actual
    end
  end

  describe "is_current_trip?/2" do
    test "returns false there is no TripInfo to compare to" do
      assert is_current_trip?(nil, "trip_id") == false
    end

    test "returns false when TripInfo sections is an empty list" do
      assert is_current_trip?(%TripInfo{sections: []}, "trip_id") == false
    end

    test "returns false when first trip in TripInfo sections doesn't match provided id" do
      assert is_current_trip?(@info, "not_trip_id") == false
    end

    test "returns true when first trip in TripInfo sections matches provided id" do
      assert is_current_trip?(@info, "trip_id") == true
    end
  end

  describe "full_status/1" do
    test "nil for bus routes" do
      actual = @info |> full_status
      expected = nil
      assert actual == expected
    end

    test "result for CR, uses the route name" do
      trip_info = %TripInfo{
        route: %Routes.Route{type: 2},
        vehicle: %Vehicles.Vehicle{status: :incoming},
        vehicle_stop_name: "Readville"
      }
      actual = trip_info |> full_status
      expected = ["Train", " is entering ", "Readville", "."]
      assert actual == expected
    end

    test "nil when there is no vehicle" do
      trip_info = %TripInfo{
        route: %Routes.Route{type: 2},
        vehicle_stop_name: "Readville"
      }
      actual = trip_info |> full_status
      expected = nil
      assert actual == expected
    end

    test "result for Subway, uses the route name" do
      trip_info = %TripInfo{
        route: %Routes.Route{type: 1},
        vehicle: %Vehicles.Vehicle{status: :stopped},
        vehicle_stop_name: "Forest Hills"
      }
      actual = trip_info |> full_status
      expected = ["Train", " has arrived at ", "Forest Hills", "."]
      assert actual == expected
    end
  end

  describe "times_with_flags_and_separators/1" do
    test "if we're showing all stops, returns one list with the times" do
      actual = times_with_flags_and_separators(@info)
      expected = [
        Enum.zip(@time_list, [%Flags{terminus?: true},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: true}])
      ]
      assert expected == actual
    end

    test "if vehicle is present, tags that as well" do
      time = List.last(@time_list)
      vehicle = %Vehicle{stop_id: PredictedSchedule.stop(time).id}
      info = from_list(@time_list, vehicle: vehicle)
      actual = times_with_flags_and_separators(info)
      expected = [
        Enum.zip(@time_list, [%Flags{terminus?: true},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: false},
                              %Flags{terminus?: true, vehicle?: true}])
      ]
      assert expected == actual
    end

    test "if we collapse, returns a list with a separator" do
      info = from_list(@time_list, collapse?: true)
      actual = times_with_flags_and_separators(info)
      assert [first_section, :separator, last_section] = actual
      assert length(first_section) == 2
      assert length(last_section) == 2
      assert List.first(first_section) == {List.first(@time_list), %Flags{terminus?: true}}
      assert List.first(last_section) == {Enum.at(@time_list, -2), %Flags{terminus?: false}}
    end
  end

  describe "should_display_trip_info?/2" do
    test "Non subway will show trip info" do
      commuter_info = %TripInfo{route: %Routes.Route{type: 4}}
      assert should_display_trip_info?(commuter_info)
    end

    test "Subway will show trip info if predictions are given" do
      subway_info = %TripInfo{sections: [%PredictedSchedule{prediction: %Prediction{time: Util.now()}}], route: %Routes.Route{type: 1}}
      assert should_display_trip_info?(subway_info)
    end

    test "Will not show trip info if there is no trip info" do
      refute should_display_trip_info?(nil)
    end
  end
end
