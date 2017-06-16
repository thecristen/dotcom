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
    @ferries ~w(Boat-Hingham Boat-Charlestown Boat-Logan Boat-Long)

    test "returns the name of the commuter rail fare given the origin and destination" do
      zone_1a = "place-north"
      zone_4 = "Ballardvale"
      zone_7 = "Haverhill"

      assert Fares.fare_for_stops(:commuter_rail, zone_1a, zone_4) == {:zone, "4"}
      assert Fares.fare_for_stops(:commuter_rail, zone_7, zone_1a) == {:zone, "7"}
      assert Fares.fare_for_stops(:commuter_rail, zone_4, zone_7) == {:interzone, "4"}
    end

    test "returns the name of the ferry fare given the origin and destination" do
      for origin_id <- @ferries,
        destination_id <- @ferries do
          both = [origin_id, destination_id]
          has_logan? = "Boat-Logan" in both
          has_charlestown? = "Boat-Charlestown" in both
          expected_name = cond do
            has_logan? and has_charlestown? -> :ferry_cross_harbor
            has_logan? -> :commuter_ferry_logan
            has_charlestown? -> :ferry_inner_harbor
            true -> :commuter_ferry
          end

          assert Fares.fare_for_stops(:ferry, origin_id, destination_id) == expected_name
      end
    end
  end
end
