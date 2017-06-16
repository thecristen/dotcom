defmodule BaseFareTest do
  use ExUnit.Case, async: true

  alias Routes.Route

  import Site.BaseFare

  test "returns an empty string if no route is provided" do
    refute base_fare(nil, nil, nil)
  end

  describe "subway" do
    @route %Route{type: 0}

    @subway_fares [%Fares.Fare{additional_valid_modes: [:bus], cents: 225, duration: :single_trip,
                      media: [:charlie_card], mode: :subway, name: :subway, reduced: nil},
                    %Fares.Fare{additional_valid_modes: [:bus], cents: 275, duration: :single_trip,
                      media: [:charlie_ticket, :cash], mode: :subway, name: :subway, reduced: nil}
                  ]

    test "returns the lowest one way trip fare that is not discounted" do
      fare_fn = fn [mode: :subway, duration: :single_trip, reduced: nil] ->
        @subway_fares
      end

      assert %Fares.Fare{cents: 225} = base_fare(@route, nil, nil, fare_fn)
    end
  end

  describe "local bus" do
    @bus_fares [%Fares.Fare{additional_valid_modes: [], cents: 170, duration: :single_trip,
                  media: [:charlie_card], mode: :bus, name: :local_bus, reduced: nil},
                %Fares.Fare{additional_valid_modes: [], cents: 200, duration: :single_trip,
                  media: [:charlie_ticket, :cash], mode: :bus, name: :local_bus, reduced: nil},
                %Fares.Fare{additional_valid_modes: [], cents: 400, duration: :single_trip,
                  media: [:charlie_card], mode: :bus, name: :inner_express_bus, reduced: nil},
                %Fares.Fare{additional_valid_modes: [], cents: 500, duration: :single_trip,
                  media: [:charlie_ticket, :cash], mode: :bus, name: :inner_express_bus,
                  reduced: nil},
                %Fares.Fare{additional_valid_modes: [], cents: 525, duration: :single_trip,
                  media: [:charlie_card], mode: :bus, name: :outer_express_bus, reduced: nil},
                %Fares.Fare{additional_valid_modes: [], cents: 700, duration: :single_trip,
                  media: [:charlie_ticket, :cash], mode: :bus, name: :outer_express_bus,
                  reduced: nil}]

    test "returns the lowest one way trip fare that is not discounted for the local bus" do
      local_route = %Route{type: 3, id: "1"}

      fare_fn = fn [name: :local_bus, duration: :single_trip, reduced: nil] ->
        Enum.filter(@bus_fares, &(&1.name == :local_bus))
      end

      assert %Fares.Fare{cents: 170} = base_fare(local_route, nil, nil, fare_fn)
    end

    test "returns the lowest one way trip fare that is not discounted for the inner express bus" do
      inner_express_route = %Route{type: 3, id: "170"}

      fare_fn = fn [name: :inner_express_bus, duration: :single_trip, reduced: nil] ->
        Enum.filter(@bus_fares, &(&1.name == :inner_express_bus))
      end

      assert %Fares.Fare{cents: 400} = base_fare(inner_express_route, nil, nil, fare_fn)
    end

    test "returns the lowerst one way trip fare that is not discounted for the outer express bus" do
      outer_express_route = %Route{type: 3, id: "352"}

      fare_fn = fn [name: :outer_express_bus, duration: :single_trip, reduced: nil] ->
        Enum.filter(@bus_fares, &(&1.name == :outer_express_bus))
      end

      assert %Fares.Fare{cents: 525} = base_fare(outer_express_route, nil, nil, fare_fn)
    end
  end

  describe "commuter rail" do
    test "returns the one way fare that is not discounted for a trip originating in Zone 1A" do
      route = %Route{type: 2}
      origin_id = "place-north"
      destination_id = "Haverhill"

      fare_fn = fn [name: {:zone, "7"}, duration: :single_trip, reduced: nil] ->
        [%Fares.Fare{additional_valid_modes: [], cents: 1050, duration: :single_trip,
          media: [:commuter_ticket, :cash], mode: :commuter_rail, name: {:zone, "7"},
          reduced: nil}]
      end

      assert %Fares.Fare{cents: 1050} = base_fare(route, origin_id, destination_id, fare_fn)
    end

    test "returns the lowest one way fare that is not discounted for a trip terminating in Zone 1A" do
      route = %Route{type: 2}
      origin_id = "Ballardvale"
      destination_id = "place-north"

      fare_fn = fn [name: {:zone, "4"}, duration: :single_trip, reduced: nil] ->
        [%Fares.Fare{additional_valid_modes: [], cents: 825, duration: :single_trip,
          media: [:commuter_ticket, :cash], mode: :commuter_rail, name: {:zone, "4"},
          reduced: nil}]
      end

      assert %Fares.Fare{cents: 825} = base_fare(route, origin_id, destination_id, fare_fn)
    end

    test "returns an interzone fare that is not discounted for a trip that does not originate/terminate in Zone 1A" do
      route = %Route{type: 2}
      origin_id = "Ballardvale"
      destination_id = "Haverhill"

      fare_fn = fn [name: {:interzone, "4"}, duration: :single_trip, reduced: nil] ->
        [%Fares.Fare{additional_valid_modes: [], cents: 401, duration: :single_trip,
          media: [:commuter_ticket, :cash], mode: :commuter_rail,
          name: {:interzone, "4"}, reduced: nil}]
      end

      assert %Fares.Fare{cents: 401} = base_fare(route, origin_id, destination_id, fare_fn)
    end
  end

  describe "ferry" do
    test "returns the fare that is not discounted for the correct ferry trip" do
      route = %Route{type: 4}
      origin_id = "Boat-Charlestown"
      destination_id = "Boat-Long"

      fare_fn = fn [name: :ferry_inner_harbor, duration: :single_trip, reduced: nil] ->
        [%Fares.Fare{additional_valid_modes: [], cents: 350, duration: :single_trip,
          media: [:charlie_ticket], mode: :ferry, name: :ferry_inner_harbor,
          reduced: nil}]
      end

      assert %Fares.Fare{cents: 350} = base_fare(route, origin_id, destination_id, fare_fn)
    end
  end
end
