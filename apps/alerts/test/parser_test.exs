defmodule Alerts.ParserTest do
  use ExUnit.Case, async: true

  test ".parse converts a JsonApi.Item into an Alerts.Alert" do
    assert Alerts.Parser.parse(
      %JsonApi.Item{
        type: "alert",
        id: "130612",
        attributes: %{
          "informed_entity" => [
            %{
              "route_type" => 3,
              "route" => "18",
              "stop" => "stop",
              "trip" => "trip",
              "direction_id" => 1
            }
          ],
          "header" => "Route 18 experiencing moderate delays due to traffic",
          "active_period" => [
            %{
              "start" => "2016-06-06T14:48:48-04:00",
              "end" => "2016-06-06T19:53:51-04:00"
            }
          ],
          "severity" => "Minor",
          "lifecycle" => "Ongoing",
          "effect_name" => "Delay",
          "updated_at" => "2016-06-20T16:09:29-04:00",
          "description" => "Affected routes: 18"
        }
      })
    ==
      %Alerts.Alert{
        id: "130612",
        header: "Route 18 experiencing moderate delays due to traffic",
        informed_entity: [
          %Alerts.InformedEntity{
            route_type: 3,
            route: "18",
            stop: "stop",
            trip: "trip",
            direction_id: 1
          }
        ],
        active_period: [
          {Timex.DateTime.from_erl({{2016, 6, 6}, {14, 48, 48}}, "Etc/GMT+4"),
           Timex.DateTime.from_erl({{2016, 6, 6}, {19, 53, 51}}, "Etc/GMT+4")}
        ],
        severity: "Minor",
        lifecycle: "Ongoing",
        effect_name: "Delay",
        updated_at: Timex.DateTime.from_erl({{2016, 6, 20}, {16, 09, 29}}, "Etc/GMT+4"),
        description: "Affected routes: 18"
      }
    end
end
