defmodule Schedules.ParserTest do
  use ExUnit.Case, async: true

  test "parse converts a JsonApi.Item into a Schedule" do
    api_item = %JsonApi.Item{
      attributes: %{
        "departure_time" => "2016-06-08T05:35:00+04:00",
        "pickup_type" => 3,
        "drop_off_type" => 0
      },
      id: "31174458-CR_MAY2016-hxl16011-Weekday-01-Lowell-schedule",
      relationships: %{
        "stop" => [
        %JsonApi.Item{
          attributes: %{
            "name" => "Lowell"
          },
          id: "Lowell",
          relationships: %{
            "parent_station" => []},
          type: "stop"}],
        "trip" => [
          %JsonApi.Item{
            attributes: %{
              "headsign" => "North Station",
              "name" => "300",
              "direction_id" => 1,
            },
            id: "31174458-CR_MAY2016-hxl16011-Weekday-01",
            relationships: %{
              "predictions" => [],
              "route" => [
                %JsonApi.Item{
                  attributes: %{
                    "long_name" => "Lowell Line",
                    "direction_names" => ["Outbound", "Inbound"],
                    "type" => 2
                  },
                  id: "CR-Lowell",
                  relationships: %{},
                  type: "route"}],
              "service" => [],
              "vehicle" => []},
            type: "trip"}]},
      type: "schedule"}

    actual = Schedules.Parser.parse(api_item)
    assert actual.route == Routes.Repo.get("CR-Lowell")
    assert actual.trip == %Schedules.Trip{
      id: "31174458-CR_MAY2016-hxl16011-Weekday-01",
      name: "300",
      headsign: "North Station",
      direction_id: 1
    }
    assert actual.stop == Stops.Repo.get!("Lowell")
    assert actual.time == Timex.to_datetime({{2016, 6, 8}, {5, 35, 0}}, "Etc/GMT-4")
    assert actual.flag?
    assert actual.pickup_type == 3
  end

  test "route parsing uses the short_name if the long_name is empty" do
    api_item = %JsonApi.Item{
      relationships: %{
        "trip" => [%JsonApi.Item{
                      relationships: %{
                        "route" => [%JsonApi.Item{
                                       type: "route",
                                       id: "9",
                                       attributes: %{
                                         "type" => 3,
                                         "short_name" => "9",
                                         "long_name" => "",
                                         "direction_names" => ["Outbound", "Inbound"],
                                         "description" => "Local Bus"
                                       }}]}}]}}
    assert Schedules.Parser.route(api_item) ==
      %Routes.Route{
        type: 3,
        id: "9",
        name: "9"
      }
  end

  describe "trip/1" do
    test "parses a trip from the API" do
      api_item = %JsonApi{
        data: [%JsonApi.Item{
                  attributes: %{"direction_id" => 1,
                                "headsign" => "Alewife", "name" => "", "wheelchair_accessible" => 1},
                  id: "31562821",
                  relationships: %{
                    "predictions" => [],
                    "route" => [%JsonApi.Item{attributes: nil, id: "Red", relationships: nil,
                                              type: "route"}],
                    "service" => [%JsonApi.Item{attributes: nil,
                                                id: "RTL42016-hms46016-Saturday-01", relationships: nil,
                                                type: "service"}], "vehicle" => []}, type: "trip"}],
        links: %{}
      }
      assert Schedules.Parser.trip(api_item) == %Schedules.Trip{
        direction_id: 1,
        headsign: "Alewife",
        id: "31562821",
        name: ""
      }
    end

    test "parses a trip as part of a schedule" do
      api_item = %JsonApi.Item{
        attributes: %{
          "departure_time" => "2016-06-08T05:35:00+04:00",
          "pickup_type" => 3,
          "drop_off_type" => 0
        },
        id: "31174458-CR_MAY2016-hxl16011-Weekday-01-Lowell-schedule",
        relationships: %{
          "stop" => [
          %JsonApi.Item{
            attributes: %{
              "name" => "Lowell"
            },
            id: "Lowell",
            relationships: %{
              "parent_station" => []},
            type: "stop"}],
          "trip" => [
            %JsonApi.Item{
              attributes: %{
                "headsign" => "North Station",
                "name" => "300",
                "direction_id" => 1,
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
                    type: "route"}],
                "service" => [],
                "vehicle" => []},
              type: "trip"}]},
        type: "schedule"}
      assert Schedules.Parser.trip(api_item) == %Schedules.Trip{
        direction_id: 1,
        headsign: "North Station",
        id: "31174458-CR_MAY2016-hxl16011-Weekday-01",
        name: "300"
      }
    end
  end
end
