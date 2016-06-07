defmodule Alerts.MatchTest do
  use ExUnit.Case, async: true

  alias Alerts.Alert
  alias Alerts.InformedEntity

  test ".match returns alerts matching the provided InformedEntity" do
    alerts = [
      %Alert{
        informed_entity: [
          %InformedEntity{
            route_type: 1,
            route: "2",
            stop: "3"
          }
        ]
      }
    ]

    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 2}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{route: "2"}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route: "21"}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{stop: "3"}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{stop: "31"}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "2"}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "21"}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "2", stop: "3"}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "2", stop: "4"}) == []
  end

  test ".match can include partially defined informed entities" do
    alerts = [
      %Alert{
        informed_entity: [
          %InformedEntity{
            route_type: 1,
            route: "2",
          }
        ]
      }
    ]

    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 2}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{route: "2"}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route: "21"}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{stop: "3"}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "2"}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "21"}) == []
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "2", stop: "3"}) == alerts
    assert Alerts.Match.match(alerts, %InformedEntity{route_type: 1, route: "2", stop: "4"}) == alerts
  end
end
