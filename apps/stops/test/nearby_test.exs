defmodule Stops.NearbyTest do
  use ExUnit.Case, async: true

  alias Stops.Stop
  import Stops.Nearby

  @latitude 42.577
  @longitude -71.225

  describe "gather_stops/5" do
    test "given no results, returns an empty list" do
      assert gather_stops(@latitude, @longitude, [], [], []) == []
    end

    test "takes the 4 closest commuter and subway stops" do
      commuter = Enum.map(0..10, fn _ -> random_stop end)
      subway = Enum.map(0..10, fn _ -> random_stop end)

      actual = gather_stops(@latitude, @longitude, commuter, subway, [])
      assert false
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
end
