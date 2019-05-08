defmodule Schedules.ParserTest do
  use ExUnit.Case, async: true

  test "parse converts a JsonApi.Item into a tuple" do
    api_item = %JsonApi.Item{
      attributes: %{
        "departure_time" => "2016-06-08T05:35:00+04:00",
        "pickup_type" => 3,
        "drop_off_type" => 1,
        "timepoint" => false
      },
      id: "31174458-CR_MAY2016-hxl16011-Weekday-01-Lowell-schedule",
      relationships: %{
        "stop" => [
          %JsonApi.Item{
            attributes: %{
              "name" => "Lowell"
            },
            id: "Lowell",
            relationships: %{"parent_station" => []},
            type: "stop"
          }
        ],
        "trip" => [
          %JsonApi.Item{
            attributes: %{
              "headsign" => "North Station",
              "name" => "300",
              "direction_id" => 1
            },
            id: "31174458-CR_MAY2016-hxl16011-Weekday-01",
            relationships: %{"predictions" => [], "service" => [], "vehicle" => []},
            type: "trip"
          }
        ],
        "route" => [
          %JsonApi.Item{
            attributes: %{
              "long_name" => "Lowell Line",
              "direction_names" => ["Outbound", "Inbound"],
              "type" => 2
            },
            id: "CR-Lowell",
            relationships: %{},
            type: "route"
          }
        ]
      },
      type: "schedule"
    }

    actual = Schedules.Parser.parse(api_item)

    assert {"CR-Lowell", "31174458-CR_MAY2016-hxl16011-Weekday-01", "Lowell",
            "2016-06-08T05:35:00+04:00", true, true, false, 0, 3} == actual
  end

  describe "trip/1" do
    test "parses a trip from the API" do
      api_item = %JsonApi{
        data: [
          %JsonApi.Item{
            attributes: %{
              "direction_id" => 1,
              "bikes_allowed" => 1,
              "headsign" => "Alewife",
              "name" => "",
              "wheelchair_accessible" => 1
            },
            id: "31562821",
            relationships: %{
              "predictions" => [],
              "route" => [
                %JsonApi.Item{attributes: nil, id: "Red", relationships: nil, type: "route"}
              ],
              "service" => [
                %JsonApi.Item{
                  attributes: nil,
                  id: "RTL42016-hms46016-Saturday-01",
                  relationships: nil,
                  type: "service"
                }
              ],
              "vehicle" => []
            },
            type: "trip"
          }
        ],
        links: %{}
      }

      assert Schedules.Parser.trip(api_item) == %Schedules.Trip{
               direction_id: 1,
               headsign: "Alewife",
               id: "31562821",
               name: "",
               bikes_allowed?: true
             }
    end

    test "parses a trip as part of a schedule" do
      api_item = %JsonApi.Item{
        attributes: %{
          "departure_time" => "2016-06-08T05:35:00+04:00",
          "pickup_type" => 3,
          "drop_off_type" => 0,
          "timepoint" => false
        },
        id: "31174458-CR_MAY2016-hxl16011-Weekday-01-Lowell-schedule",
        relationships: %{
          "stop" => [
            %JsonApi.Item{
              attributes: %{
                "name" => "Lowell"
              },
              id: "Lowell",
              relationships: %{"parent_station" => []},
              type: "stop"
            }
          ],
          "trip" => [
            %JsonApi.Item{
              attributes: %{
                "headsign" => "North Station",
                "name" => "300",
                "direction_id" => 1,
                "bikes_allowed" => 1
              },
              id: "31174458-CR_MAY2016-hxl16011-Weekday-01",
              relationships: %{
                "predictions" => [],
                "route" => [
                  %JsonApi.Item{
                    attributes: %{
                      "long_name" => "Lowell Line",
                      "type" => 2
                    },
                    id: "CR-Lowell",
                    relationships: %{},
                    type: "route"
                  }
                ],
                "service" => [],
                "vehicle" => []
              },
              type: "trip"
            }
          ]
        },
        type: "schedule"
      }

      assert Schedules.Parser.trip(api_item) == %Schedules.Trip{
               direction_id: 1,
               headsign: "North Station",
               id: "31174458-CR_MAY2016-hxl16011-Weekday-01",
               name: "300",
               bikes_allowed?: true
             }
    end

    test "interprets a trip with relationships with no attributes as nil" do
      api_item = %JsonApi.Item{
        attributes: %{
          "arrival_time" => nil,
          "departure_time" => nil,
          "direction_id" => 0,
          "schedule_relationship" => "UNSCHEDULED",
          "status" => "1 stop away",
          "stop_sequence" => nil,
          "track" => nil
        },
        id: "prediction-3690-3864-place-pktrm-",
        relationships: %{
          "route" => [
            %JsonApi.Item{
              attributes: nil,
              id: "Green-B",
              relationships: nil,
              type: "route"
            }
          ],
          "schedule" => [],
          "stop" => [
            %JsonApi.Item{
              attributes: nil,
              id: "place-pktrm",
              relationships: nil,
              type: "stop"
            }
          ],
          "trip" => [
            %JsonApi.Item{
              attributes: nil,
              id: "3690-3864",
              relationships: nil,
              type: "trip"
            }
          ]
        },
        type: "schedule"
      }

      assert Schedules.Parser.trip(api_item) == nil
    end

    test "interprets a trip with relationships of an empty list as nil" do
      api_item = %JsonApi.Item{
        attributes: %{
          "arrival_time" => nil,
          "departure_time" => nil,
          "direction_id" => 0,
          "schedule_relationship" => "UNSCHEDULED",
          "status" => "1 stop away",
          "stop_sequence" => nil,
          "track" => nil
        },
        id: "schedule-3690-3864-place-pktrm-",
        relationships: %{
          "route" => [
            %JsonApi.Item{
              attributes: nil,
              id: "Green-B",
              relationships: nil,
              type: "route"
            }
          ],
          "schedule" => [],
          "stop" => [
            %JsonApi.Item{
              attributes: nil,
              id: "place-pktrm",
              relationships: nil,
              type: "stop"
            }
          ],
          "trip" => []
        },
        type: "schedule"
      }

      assert Schedules.Parser.trip(api_item) == nil
    end
  end
end
