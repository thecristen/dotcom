defmodule ExcludedStopsTest do
  use ExUnit.Case, async: true
  import ExcludedStops

  describe "excluded_origin_stops/3" do
    test "excludes the last stop on a non-Red line" do
      all_stops = Enum.map(1..10, & %{id: Integer.to_string(&1)})

      assert excluded_origin_stops(0, "Route", all_stops) == ["10"]
    end

    test "excludes both terminals on southbound Red Line trips" do
      assert excluded_origin_stops(0, "Red", []) == ["place-brntn", "place-asmnl"]
    end

    test "excludes last terminal on northbound Red Line trips" do
      all_stops = Enum.map(1..10, & %{id: Integer.to_string(&1)})

      assert excluded_origin_stops(1, "Red", all_stops) == ["10"]
    end

    test "if no stops are passed, returns the empty list" do
      assert excluded_origin_stops(1, "Route", []) == []
    end
  end

  describe "excluded_destination_stops/2" do
    test "excludes nothing for non-Red lines" do
      assert excluded_destination_stops("Green-B", "place-pktrm") == []
    end

    test "excludes Ashmont stops if the origin is on the Braintree branch" do
      assert "place-smmnl" in excluded_destination_stops("Red", "place-brntn")
    end

    test "excludes Braintree stops if the origin is on the Ashmont branch" do
      assert "place-qamnl" in excluded_destination_stops("Red", "place-asmnl")
    end
  end
end
