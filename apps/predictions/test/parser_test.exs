defmodule Predictions.ParserTest do
  use ExUnit.Case, async: true

  alias Predictions.Parser
  alias Predictions.Prediction
  alias JsonApi.Item
  alias Timex.Timezone

  describe "parse/1" do
    test "parses a %JsonApi.Item{} into %Prediction{}" do
      item = %Item{
        attributes: %{
          "track" => nil,
          "status" => "On Time",
          "direction_id" => 0,
          "departure_time" => "2016-09-15T15:40:00-04:00",
          "arrival_time" => "2016-01-01T00:00:00-04:00"
        },
        relationships: %{
          "route" => [%Item{id: "route_id"}, %Item{id: "wrong"}],
          "stop" => [%Item{id: "stop_id"}, %Item{id: "wrong"}],
          "trip" => [%Item{id: "trip_id"}, %Item{id: "wrong"}]
        }
      }
      expected = %Prediction{
        trip_id: "trip_id",
        stop_id: "stop_id",
        route_id: "route_id",
        direction_id: 0,
        time: ~N[2016-09-15T19:40:00] |> Timezone.convert("Etc/GMT+4"),
        track: nil,
        status: "On Time"
      }

      assert Parser.parse(item) == expected
    end

    test "uses arrival time if departure time isn't available" do
      item = %Item{
        attributes: %{
          "track" => nil,
          "status" => "On Time",
          "direction_id" => 0,
          "departure_time" => nil,
          "arrival_time" => "2016-09-15T15:40:00+01:00",
        },
        relationships: %{
          "route" => [%Item{id: "route_id"}, %Item{id: "wrong"}],
          "stop" => [%Item{id: "stop_id"}, %Item{id: "wrong"}],
          "trip" => [%Item{id: "trip_id"}, %Item{id: "wrong"}]
        }
      }

      assert Parser.parse(item).time == ~N[2016-09-15T14:40:00] |> Timezone.convert("Etc/GMT-1")
    end

    test "uses parent station ID if present" do
      item = %Item{
        attributes: %{
          "track" => nil,
          "status" => "On Time",
          "direction_id" => 0,
          "departure_time" => "2016-09-15T15:40:00-04:00",
          "arrival_time" => nil
        },
        relationships: %{
          "route" => [%Item{id: "route_id"}],
          "stop" => [%Item{id: "stop_id",
                           relationships: %{
                             "parent_station" => [
                             %Item{id: "parent_id"}
                           ]
                           }}],
          "trip" => [%Item{id: "trip_id"}]
        }
      }
      expected = "parent_id"
      actual = Parser.parse(item).stop_id

      assert actual == expected
    end

    test "can parse possible schedule relationships" do
      base_item = %Item{
        attributes: %{
          "track" => nil,
          "status" => "On Time",
          "direction_id" => 0,
          "departure_time" => "2016-09-15T15:40:00-04:00",
          "arrival_time" => "2016-01-01T00:00:00-04:00"
        },
        relationships: %{
          "route" => [%Item{id: "route_id"}, %Item{id: "wrong"}],
          "stop" => [%Item{id: "stop_id"}, %Item{id: "wrong"}],
          "trip" => [%Item{id: "trip_id"}, %Item{id: "wrong"}]
        }
      }

      for {json, expected} <- [
            {nil, nil},
            {"unknown", nil},
            {"ADDED", :added},
            {"SKIPPED", :skipped},
            {"CANCELLED", :cancelled},
            {"UNSCHEDULED", :unscheduled},
            {"NO_DATA", :no_data}
          ] do
          # update the item to set the given JSON relationship
          item = %{base_item | attributes: Map.put(base_item.attributes, "schedule_relationship", json)}
          assert Parser.parse(item).schedule_relationship == expected
      end
    end
  end
end
