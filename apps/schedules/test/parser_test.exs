defmodule Schedules.ParserTest do
  use ExUnit.Case, async: true

  test "parse converts a JsonApi.Item into a Schedule" do
    api_item = %JsonApi.Item{
      attributes: %{
        "departure_time" => "2016-06-08T05:35:00+04:00"
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

    expected = %Schedules.Schedule{
      route: %Routes.Route{
        id: "CR-Lowell",
        type: 2,
        name: "Lowell Line"},
      trip: %Schedules.Trip{
        id: "31174458-CR_MAY2016-hxl16011-Weekday-01",
        name: "300",
        headsign: "North Station",
        direction_id: 1
      },
      stop: %Schedules.Stop{
        id: "Lowell",
        name: "Lowell"
      },
      time: Timex.to_datetime({{2016, 6, 8}, {5, 35, 0}}, "Etc/GMT-4"),
    }

    assert Schedules.Parser.parse(api_item) == expected
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
                                         "description" => "Local Bus"
                                       }}]}}]}}
    assert Schedules.Parser.route(api_item) ==
      %Routes.Route{
        type: 3,
        id: "9",
        name: "9"
      }
  end
end
