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
  end
end
