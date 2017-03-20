defmodule Alerts.ParserTest do
  use ExUnit.Case, async: true

  alias Alerts.Parser

  describe "Alert.parse/1" do
    test ".parse converts a JsonApi.Item into an Alerts.Alert" do
      assert Parser.Alert.parse(
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
          {~N[2016-06-06T14:48:48] |> Timex.to_datetime("Etc/GMT+4"),
           ~N[2016-06-06T19:53:51] |> Timex.to_datetime("Etc/GMT+4")}
        ],
        severity: "Minor",
        lifecycle: "Ongoing",
        effect_name: "Delay",
        updated_at: ~N[2016-06-20T16:09:29] |> Timex.to_datetime("Etc/GMT+4"),
        description: "Affected routes: 18"
      }
    end
    test "Whitespace is trimmed from description" do
      assert %Alerts.Alert{description: "Affected routes:\t18"}
      =
      Parser.Alert.parse(
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
            "description" => "\n\r\tAffected routes:\t18\n\r\t"
          }
        })
    end
  end
end
