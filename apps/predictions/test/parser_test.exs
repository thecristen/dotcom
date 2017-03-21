defmodule Predictions.ParserTest do
  use ExUnit.Case, async: true

  alias Predictions.Parser
  alias Predictions.Prediction
  alias Schedules.Stop
  alias Schedules.Trip
  alias Routes.Route
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
          "arrival_time" => "2016-01-01T00:00:00-04:00",
          "stop_sequence" => 5
        },
        relationships: %{
          "route" => [%Item{id: "route_id", attributes: %{
                               "long_name" => "Route",
                               "direction_names" => ["Eastbound", "Westbound"],
                               "type" => 5
                            }},
                      %Item{id: "wrong"}],
          "stop" => [%Item{id: "stop_id", attributes: %{"name" => "Stop"}}, %Item{id: "wrong"}],
          "trip" => [%Item{id: "trip_id", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }},
                     %Item{id: "wrong", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }}]
        }
      }
      expected = %Prediction{
        trip: %Trip{id: "trip_id", name: "trip_name", direction_id: "0", headsign: "trip_headsign"},
        stop: %Stop{id: "stop_id", name: "Stop"},
        route: %Route{
          id: "route_id",
          name: "Route",
          key_route?: false,
          direction_names: %{0 => "Eastbound", 1 => "Westbound"},
          type: 5
        },
        direction_id: 0,
        time: ~N[2016-09-15T19:40:00] |> Timezone.convert("Etc/GMT+4"),
        stop_sequence: 5,
        track: nil,
        status: "On Time",
        departing?: true
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
          "route" => [%Item{id: "route_id", attributes: %{
                               "long_name" => "Route",
                               "direction_names" => ["Eastbound", "Westbound"],
                               "type" => 5
                            }},
                      %Item{id: "wrong"}],
          "stop" => [%Item{id: "stop_id", attributes: %{"name" => "Stop"}}, %Item{id: "wrong"}],
          "trip" => [%Item{id: "trip_id", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }},
                     %Item{id: "wrong", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }}]
        }
      }
      parsed = Parser.parse(item)

      assert parsed.time == ~N[2016-09-15T14:40:00] |> Timezone.convert("Etc/GMT-1")
      refute parsed.departing?
    end

    test "can parse a prediction with no times" do
      item = %Item{
        attributes: %{
          "track" => nil,
          "status" => "On Time",
          "direction_id" => 0,
          "departure_time" => nil,
          "arrival_time" => nil,
        },
        relationships: %{
          "route" => [%Item{id: "route_id", attributes: %{
                               "long_name" => "Route",
                               "direction_names" => ["Eastbound", "Westbound"],
                               "type" => 5
                            }},
                      %Item{id: "wrong"}],
          "stop" => [%Item{id: "stop_id", attributes: %{"name" => "Stop"}}, %Item{id: "wrong"}],
          "trip" => [%Item{id: "trip_id", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }},
                     %Item{id: "wrong", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }}]
        }
      }
      parsed = Parser.parse(item)

      assert parsed.time == nil
      refute parsed.departing?
    end

    test "uses parent station ID and name if present" do
      item = %Item{
        attributes: %{
          "track" => nil,
          "status" => "On Time",
          "direction_id" => 0,
          "departure_time" => "2016-09-15T15:40:00-04:00",
          "arrival_time" => nil
        },
        relationships: %{
          "route" => [%Item{id: "route_id", attributes: %{
                               "long_name" => "Route",
                               "direction_names" => ["Eastbound", "Westbound"],
                               "type" => 5
                            }}],
          "stop" => [%Item{id: "stop_id",
                           attributes: %{"name" => "Stop - Outbound"},
                           relationships: %{
                             "parent_station" => [
                             %Item{id: "parent_id", attributes: %{"name" => "Parent Name"}}
                           ]
                           }}],
          "trip" => [%Item{id: "trip_id", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }}]
        }
      }
      expected = %Stop{name: "Parent Name", id: "parent_id"}
      actual = Parser.parse(item).stop

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
          "route" => [%Item{id: "route_id", attributes: %{
                               "long_name" => "Route",
                               "direction_names" => ["Eastbound", "Westbound"],
                               "type" => 5
                            }},
                      %Item{id: "wrong"}],
          "stop" => [%Item{id: "stop_id", attributes: %{"name" => "Stop"}}, %Item{id: "wrong"}],
          "trip" => [%Item{id: "trip_id", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }},
                     %Item{id: "wrong", attributes: %{
                              "name" => "trip_name",
                              "direction_id" => "0",
                              "headsign" => "trip_headsign"
                           }}]
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

    test "can handle empty trip relationships" do
      item = %Item{
        attributes: %{
          "track" => nil,
          "status" => "On Time",
          "direction_id" => 0,
          "departure_time" => "2016-09-15T15:40:00-04:00",
          "arrival_time" => "2016-01-01T00:00:00-04:00"
        },
        relationships: %{
          "route" => [%Item{id: "route_id", attributes: %{
                               "long_name" => "Route",
                               "direction_names" => ["Eastbound", "Westbound"],
                               "type" => 5
                            }}],
          "stop" => [%Item{id: "stop_id", attributes: %{"name" => "Stop"}}],
          "trip" => []
        }
      }
      expected = %Prediction{
        trip: nil,
        stop: %Stop{id: "stop_id", name: "Stop"},
        route: %Route{
          id: "route_id",
          name: "Route",
          key_route?: false,
          direction_names: %{0 => "Eastbound", 1 => "Westbound"},
          type: 5
        },
        direction_id: 0,
        time: ~N[2016-09-15T19:40:00] |> Timezone.convert("Etc/GMT+4"),
        track: nil,
        status: "On Time",
        departing?: true
      }

      assert Parser.parse(item) == expected
    end
  end
end
