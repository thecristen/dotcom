defmodule Site.FareController.FerryTest do
  use ExUnit.Case, async: true
  use ExCheck

  # a subset of possible ferry stops
  @ferries ~w(Boat-Hingham Boat-Charlestown Boat-Logan Boat-Long)

  _ = @tag iterations: 30
  property :fare_name do
    for_all {origin_id, destination_id} in {elements(@ferries), elements(@ferries)} do
      both = [origin_id, destination_id]
      has_logan? = "Boat-Logan" in both
      has_charlestown? = "Boat-Charlestown" in both
      expected_name = cond do
        has_logan? and has_charlestown? -> :ferry_cross_harbor
        has_logan? -> :commuter_ferry_logan
        has_charlestown? -> :ferry_inner_harbor
        true -> :commuter_ferry
      end

      Site.FareController.Ferry.fare_name(origin_id, destination_id) == expected_name
    end
  end
end
