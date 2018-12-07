defmodule FaresTest do
  use ExUnit.Case, async: true
  doctest Fares

  describe "calculate_commuter_rail/2" do
    test "when the origin is zone 6, finds the zone 6 fares" do
      assert Fares.calculate_commuter_rail("6", "1A") == {:zone, "6"}
    end

    test "given two stops, finds the interzone fares" do
      assert Fares.calculate_commuter_rail("3", "5") == {:interzone, "3"}
    end

    test "when the origin is zone 1a, finds the fare based on destination" do
      assert Fares.calculate_commuter_rail("1A", "4") == {:zone, "4"}
    end
  end

  describe "fare_for_stops/3" do
    # a subset of possible ferry stops
    @ferries ~w(Boat-Hingham Boat-Charlestown Boat-Logan Boat-Long-South)

    test "returns the name of the commuter rail fare given the origin and destination" do
      zone_1a = "place-north"
      zone_4 = "Ballardvale"
      zone_7 = "Haverhill"

      assert Fares.fare_for_stops(:commuter_rail, zone_1a, zone_4) == {:ok, {:zone, "4"}}
      assert Fares.fare_for_stops(:commuter_rail, zone_7, zone_1a) == {:ok, {:zone, "7"}}
      assert Fares.fare_for_stops(:commuter_rail, zone_4, zone_7) == {:ok, {:interzone, "4"}}
    end

    test "returns an error if the fare doesn't exist" do
      assert Fares.fare_for_stops(:commuter_rail, "place-north", "place-pktrm") == :error
    end

    test "returns the name of the ferry fare given the origin and destination" do
      for origin_id <- @ferries,
          destination_id <- @ferries do
        both = [origin_id, destination_id]
        has_logan? = "Boat-Logan" in both
        has_charlestown? = "Boat-Charlestown" in both
        has_long? = "Boat-Long" in both
        has_long_south? = "Boat-Long-South" in both

        expected_name =
          cond do
            has_logan? and has_charlestown? -> :ferry_cross_harbor
            has_long? and has_logan? -> :ferry_cross_harbor
            has_long_south? and has_charlestown? -> :ferry_inner_harbor
            has_logan? -> :commuter_ferry_logan
            true -> :commuter_ferry
          end

        assert Fares.fare_for_stops(:ferry, origin_id, destination_id) == {:ok, expected_name}
      end
    end
  end
end
