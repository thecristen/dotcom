defmodule Stops.NearbyTest do
  use ExUnit.Case, async: true

  alias Stops.Stop
  import Stops.Nearby

  @latitude 42.577
  @longitude -71.225
  @position {@latitude, @longitude}

  describe "gather_stops/5" do
    test "given no results, returns an empty list" do
      assert gather_stops(@position, [], [], []) == []
    end

    test "takes the 4 closest commuter and subway stops" do
      commuter = random_stops(10)
      subway = random_stops(10)

      actual = gather_stops(@position, commuter, subway, [])

      [first_commuter | commuter_sorted] = commuter |> distance_sort
      [first_subway | subway_sorted] = subway |> distance_sort
      assert first_commuter in actual
      assert first_subway in actual
      assert ((commuter_sorted ++ subway_sorted) |> distance_sort |> List.first) in actual
      assert ((commuter_sorted ++ subway_sorted) |> distance_sort |> Enum.at(1)) in actual
    end

    test "if there are no CR or Bus stops, takes the 12 closest subway" do
      subway = random_stops(20)

      actual = gather_stops(@position, [], subway, [])
      assert Stops.Distance.closest(subway, @position, 12) == actual
    end

    test "if there are no Subway or Bus stops, takes the 4 closest CR" do
      commuter = random_stops(10)

      actual = gather_stops(@position, commuter, [], [])
      assert Stops.Distance.closest(commuter, @position, 4) == actual
    end

    test "if subway and CR stops overlap, does not return duplicates" do
      both = random_stops(20)

      actual = gather_stops(@position, both, both, [])
      assert Stops.Distance.closest(both, @position, 12) == actual
    end

    test "if non-closest subway and CR stops overlap, does not return duplicates" do
      commuter = random_stops(1)
      subway = [%{id: "very close", latitude: @latitude, longitude: @longitude}]

      actual = gather_stops(@position, commuter, subway ++ commuter, [])
      assert [_, _] = actual
    end

    test "returns 12 closest bus stops" do
      bus = random_stops(20)

      actual = gather_stops(@position, [], [], bus)
      assert Stops.Distance.closest(bus, @position, 12) == actual
    end

    test "with subway and commuter, returns 8 bus stops" do
      commuter = random_stops(10)
      subway = random_stops(10)
      bus = random_stops(10)

      actual = gather_stops(@position, commuter, subway, bus)

      assert length(actual) == 12

      for stop <- Stops.Distance.closest(bus, @position, 8) do
        assert stop in actual
      end

      assert (commuter |> Stops.Distance.closest(@position, 1) |> List.first) in actual
      assert (subway |> Stops.Distance.closest(@position, 1) |> List.first) in actual
    end

    test "without enough bus stops, fill with subway" do
      commuter = random_stops(10)
      subway = random_stops(10)
      bus = random_stops(4)

      actual = gather_stops(@position, commuter, subway, bus)

      assert length(actual) == 12
    end

    test "does not include duplicate stops" do
      all = random_stops(20)

      actual = gather_stops(@position, all, all, all)
      assert Stops.Distance.closest(all, @position, 12) == actual
    end

    test "stops are always globally sorted" do
      actual = gather_stops(@position, random_stops(10), random_stops(10), random_stops(10))

      assert Stops.Distance.sort(actual, @position) == actual
    end
  end

  def random_stops(count) do
    Enum.map(1..count, fn _ -> random_stop end)
  end

  defp random_stop do
    id = System.unique_integer |> Integer.to_string
    %Stop{
      id: id,
      name: "Stop #{id}",
      latitude: random_around(@latitude),
      longitude: random_around(@longitude)
    }
  end

  defp random_around(float, range \\ 10000) do
    integer = :crypto.rand_uniform(-1 * range, range)
    float + (integer / range)
  end

  defp distance_sort(stops) do
    Stops.Distance.sort(stops, {@latitude, @longitude})
  end
end
