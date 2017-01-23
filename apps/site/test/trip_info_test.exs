defmodule TripInfoTest do
  use ExUnit.Case, async: true
  import TripInfo
  alias TripInfo.Flags

  alias Routes.Route
  alias Schedules.{Schedule, Stop}
  alias Vehicles.Vehicle
  import :erlang, only: [iolist_to_binary: 1]

  @route %Route{id: "1", name: "1", type: 2}
  @info %TripInfo{
    route: @route,
    origin: "place-sstat",
    destination: "place-pktrm",
    duration: 60 * 24 * 2, # 2 day duration trip
    times: [%Schedule{
               time: ~N[2017-01-01T00:00:00],
               route: @route,
               stop: %Stop{id: "place-sstat", name: "South Station"}},
            %Schedule{
              time: ~N[2017-01-02T00:00:00],
              route: @route,
              stop: %Stop{id: "place-north", name: "North Station"}},
            %Schedule{
              time: ~N[2017-01-02T12:00:00],
              route: @route,
              stop: %Stop{id: "place-censq", name: "Central Square"}},
            %Schedule{
              time: ~N[2017-01-03T00:00:00],
              route: @route,
              stop: %Stop{id: "place-pktrm", name: "Park Street"}}]}

  describe "from_list/1" do
    test "creates a TripInfo from a list of Schedules" do
      actual = from_list(@info.times)
      expected = @info
      assert actual == expected
    end

    test "creates a TripInfo with origin/destination even when they are passed in as nil" do
      actual = from_list(@info.times, origin: nil, destination: nil)
      expected = @info
      assert actual == expected
    end

    test "given an origin, limits the times to just those after origin" do
      actual = from_list(@info.times, origin: "place-north")
      assert List.first(actual.times).stop.id == "place-north"
      assert actual.duration == 60 * 24 # 1 day trip
    end

    test "given an origin and destination, limits both sides" do
      actual = from_list(@info.times, origin: "place-north", destination: "place-censq")
      assert List.first(actual.times).stop.id == "place-north"
      assert List.last(actual.times).stop.id == "place-censq"
      assert actual.duration == 60 * 12 # 12 hour trip
    end

    test "if there are not enough times, returns an error" do
      actual = from_list(@info.times |> Enum.take(1))
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
      expected = Enum.zip(@info.times, [%Flags{terminus?: true},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: true}])
      assert expected == actual
    end

    test "if vehicle is present, then tags that as well" do
      time = List.last(@info.times)
      vehicle = %Vehicle{stop_id: time.stop.id}
      info = from_list(@info.times, vehicle: vehicle)
      actual = times_with_flags(info)
      expected = Enum.zip(@info.times, [%Flags{terminus?: true},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: false},
                                        %Flags{terminus?: true, vehicle?: true}])
      assert expected == actual
    end
  end
end
