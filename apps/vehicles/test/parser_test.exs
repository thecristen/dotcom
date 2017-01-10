defmodule Vehicles.ParserTest do
  use ExUnit.Case, async: true
  alias Vehicles.{Parser, Vehicle}

  @item %JsonApi.Item{
    attributes: %{
      "current_status" => "STOPPED_AT",
      "direction_id" => 1,
    },
    id: "y1799",
    relationships: %{
      "route" => [%JsonApi.Item{id: "1"}],
      "stop" => [%JsonApi.Item{id: "72"}],
      "trip" => [%JsonApi.Item{id: "32893540"}]
    },
    type: "vehicle"
  }

  describe "parse/1" do
    test "parses an API response into a Vehicle struct" do
      expected = %Vehicle{
        id: "y1799",
        route_id: "1",
        stop_id: "72",
        trip_id: "32893540",
        direction_id: 1,
        status: :stopped
      }
      assert Parser.parse(@item) == expected
    end

    test "can handle a nil trip" do
      item = %{@item | relationships: Map.put(@item.relationships, "trip", nil)}

      expected = %Vehicle{
        id: "y1799",
        route_id: "1",
        stop_id: "72",
        trip_id: nil,
        direction_id: 1,
        status: :stopped
      }
      assert Parser.parse(item) == expected
    end

    test "parses parent stop relationships if present" do
      item = %JsonApi.Item{
        attributes: %{
          "current_status" => "IN_TRANSIT_TO",
          "direction_id" => 0,
        },
        id: "544B1E1A",
        relationships: %{
          "route" => [%JsonApi.Item{id: "Red"}],
          "stop" => [%JsonApi.Item{id: "70068", relationships: %{
                                      "parent_station" => [%JsonApi.Item{id: "place-harsq"}]
                                   }}],
          "trip" => [%JsonApi.Item{id: "32542428"}]
        },
        type: "vehicle"
      }

      expected = %Vehicle{
        id: "544B1E1A",
        route_id: "Red",
        stop_id: "place-harsq",
        trip_id: "32542428",
        direction_id: 0,
        status: :in_transit
      }

      assert Parser.parse(item) == expected
    end
  end
end
