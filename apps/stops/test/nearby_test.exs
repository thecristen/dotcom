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
      commuter = Enum.map(0..10, fn _ -> random_stop end)
      subway = Enum.map(0..10, fn _ -> random_stop end)

      actual = gather_stops(@position, commuter, subway, [])

      [first_commuter | commuter_sorted] = commuter |> distance_sort
      [first_subway | subway_sorted] = subway |> distance_sort
      assert first_commuter in actual
      assert first_subway in actual
      assert ((commuter_sorted ++ subway_sorted) |> distance_sort |> List.first) in actual
      assert ((commuter_sorted ++ subway_sorted) |> distance_sort |> Enum.at(1)) in actual
    end

    test "if there are no CR stops, takes the 4 closest subway" do
      subway = Enum.map(0..10, fn _ -> random_stop end)

      actual = gather_stops(@position, [], subway, [])
      assert Stops.Distance.closest(subway, @position, 4) == actual
    end

    test "if there are no Subway stops, takes the 4 closest CR" do
      commuter = Enum.map(0..10, fn _ -> random_stop end)

      actual = gather_stops(@position, commuter, [], [])
      assert Stops.Distance.closest(commuter, @position, 4) == actual
    end

    test "if subway and CR stops overlap, does not return duplicates" do
      both = Enum.map(0..10, fn _ -> random_stop end)

      actual = gather_stops(@position, both, both, [])
      assert Stops.Distance.closest(both, @position, 4) == actual
    end
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

  defp random_around(float, range \\ 1000) do
    integer = :crypto.rand_uniform(-1 * range, range)
    float + (integer / range)
  end

  defp distance_sort(stops) do
    Stops.Distance.sort(stops, {@latitude, @longitude})
  end
end
