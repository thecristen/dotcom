defmodule Fares.RetailLocationsTest do
  use ExUnit.Case, async: true

  @with_nearby %Stops.Stop{latitude: 42.352271, longitude: -71.055242, id: "place-sstat"}

  describe "Fares.RetailLocations.get_nearby/1" do
    @tag fare_retail_locations: true
    test "returns retail locations near a stop" do
      locations = Fares.RetailLocations.get_nearby @with_nearby
      assert is_list locations
      assert length(locations) > 0
    end

    test "returns no more than 4 locations" do
      assert length(Fares.RetailLocations.get_nearby(@with_nearby)) == 4
    end

    test "returns the closest locations possible" do
      {_, top_distance} = @with_nearby |> Fares.RetailLocations.get_nearby() |> List.first

      assert Fares.RetailLocations.Data.get
      |> Enum.map(&Map.from_struct/1)
      |> Enum.map(&(Stops.Distance.haversine(&1, @with_nearby)))
      |> Enum.sort
      |> List.first == top_distance
    end
  end
end
