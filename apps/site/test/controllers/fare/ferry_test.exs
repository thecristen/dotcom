defmodule Site.FareController.FerryTest do
  use ExUnit.Case, async: true

  # a subset of possible ferry stops
  @ferries ~w(Boat-Hingham Boat-Charlestown Boat-Logan Boat-Long)

  test "fare_name/2" do
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

        assert Site.FareController.Ferry.fare_name(origin_id, destination_id) == expected_name
    end
  end
end
