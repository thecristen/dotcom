defmodule TripInfoTest do
  use ExUnit.Case, async: true
  import TripInfo
  alias TripInfo.Flags

  alias Routes.Route
  alias Schedules.Schedule
  alias Vehicles.Vehicle
  import :erlang, only: [iolist_to_binary: 1]

  @route %Route{id: "1", name: "1", type: 2}
  @time_list [
    %Schedule{
      time: ~N[2017-01-01T00:00:00],
      route: @route,
      stop: %Schedules.Stop{id: "place-sstat", name: "South Station"}},
    %Schedule{
      time: ~N[2017-01-02T00:00:00],
      route: @route,
      stop: %Schedules.Stop{id: "place-north", name: "North Station"}},
    %Schedule{
      time: ~N[2017-01-02T12:00:00],
      route: @route,
      stop: %Schedules.Stop{id: "place-censq", name: "Central Square"}},
    %Schedule{
      time: ~N[2017-01-02T18:00:00],
      route: @route,
      stop: %Schedules.Stop{id: "place-harsq", name: "Harvard Square"}},
    %Schedule{
      time: ~N[2017-01-03T00:00:00],
      route: @route,
      stop: %Schedules.Stop{id: "place-pktrm", name: "Park Street"}}]
  @info %TripInfo{
    route: @route,
    origin_id: "place-sstat",
    destination_id: "place-pktrm",
    duration: 60 * 24 * 2, # 2 day duration trip
    times: @time_list,
    sections: [@time_list]}

  describe "from_list/1" do
    test "creates a TripInfo from a list of Schedules" do
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
      assert List.first(actual.times).stop.id == "place-north"
      assert actual.duration == 60 * 24 # 1 day trip
    end

    test "given an origin and destination, limits both sides" do
      actual = from_list(@time_list, origin_id: "place-north", destination_id: "place-censq")
      assert List.first(actual.times).stop.id == "place-north"
      assert List.last(actual.times).stop.id == "place-censq"
      assert actual.duration == 60 * 12 # 12 hour trip
    end

    test "given an origin/destination/vehicle, keeps stops before the origin if the vehicle is there" do
      actual = from_list(@time_list, origin_id: "place-censq", destination_id: "place-harsq", vehicle: %Vehicle{stop_id: "place-north"})
      assert List.first(actual.times).stop.id == "place-north"
      assert List.last(actual.times).stop.id == "place-harsq"
      assert actual.duration == 60 * 6 # 6 hour trip from censq to harsq
    end

    test "given an origin/destination/vehicle, does not keep stops before the origin if the vehicle is after the origin" do
      actual = from_list(@time_list, origin_id: "place-north", destination_id: "place-harsq", vehicle: %Vehicle{stop_id: "place-censq"})
      assert List.first(actual.times).stop.id == "place-north"
      assert List.last(actual.times).stop.id == "place-harsq"
      assert actual.duration == 60 * 18
    end

    test "if collapse? is true, shows the origin + 1 after, destination + 1 before" do
      actual = from_list(@time_list, collapse?: true)
      assert actual.sections == [Enum.take(@time_list, 2), Enum.take(@time_list, -2)]
      assert actual.duration == @info.duration
    end

    test "if collapse? is false but there are not enough stops, display them all" do
      actual = from_list(@time_list, origin_id: "place-north", collapse?: true)
      assert actual.sections == [Enum.drop(@time_list, 1)]
    end

    test "if there are not enough times, returns an error" do
      actual = @time_list |> Enum.take(1) |> from_list
      assert {:error, _} = actual
    end
  end

  describe "full_status/1" do
    test "returns status with Bus Route for bus routes" do
      actual = @info |> full_status |> iolist_to_binary
      expected = "Bus Route 1 to Park Street operating at normal schedule"
      assert actual == expected
    end

    test "uses the route name" do
      actual = %{@info | route: %Route{id: "Red", name: "Red Line"}} |> full_status |> iolist_to_binary
      expected = "Red Line to Park Street operating at normal schedule"
      assert actual == expected
    end
  end

  describe "times_with_flags/1" do
    test "returns the times, tagging the first and last stops as termini" do
      actual = times_with_flags(@info)
      expected = Enum.zip(@time_list, [%Flags{terminus?: true},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: true}])
      assert expected == actual
    end

    test "if vehicle is present, then tags that as well" do
      time = List.last(@time_list)
      vehicle = %Vehicle{stop_id: time.stop.id}
      info = from_list(@time_list, vehicle: vehicle)
      actual = times_with_flags(info)
      expected = Enum.zip(@time_list, [%Flags{terminus?: true},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: true, vehicle?: true}])
      assert expected == actual
    end
  end

  describe "times_with_flags_and_separators/1" do
    test "if we're showing all stops, returns one list with the times" do
      actual = times_with_flags_and_separators(@info)
      expected = [times_with_flags(@info)]
      assert expected == actual
    end

    test "if we collapse, returns a list with a separator" do
      info = from_list(@time_list, collapse?: true)
      actual = times_with_flags_and_separators(info)
      assert [first_section, :separator, last_section] = actual
      assert length(first_section) == 2
      assert length(last_section) == 2
      assert List.first(first_section) == {List.first(@time_list), %Flags{terminus?: true}}
      assert List.first(last_section) == {Enum.at(@time_list, 3), %Flags{terminus?: false}}
    end
  end
end
