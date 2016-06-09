defmodule Alerts.MatchTest do
  use ExUnit.Case, async: true
  use Timex

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

  test ".match can take a datetime to filter further" do
    alerts = [
      %Alert{
        informed_entity: [
          %InformedEntity{stop: "1"}
        ],
        active_period: [
          {nil, DateTime.from({{2016, 6, 1}, {0, 0, 0}})},
          {DateTime.from({{2016, 6, 2}, {0, 0, 0}}), DateTime.from({{2016, 6, 2}, {1, 0, 0}})},
          {DateTime.from({{2016, 6, 3}, {0, 0, 0}}), nil}
        ]
      }
    ]
    ie = %InformedEntity{stop: "1"}

    assert Alerts.Match.match(alerts, ie) == alerts
    assert Alerts.Match.match(alerts, ie, DateTime.from({{2016, 6, 2}, {0, 30, 0}})) == alerts
    assert Alerts.Match.match(alerts, ie, DateTime.from({{2016, 6, 4}, {0, 0, 0}})) == alerts
    assert Alerts.Match.match(alerts, ie, DateTime.from({{2016, 5, 20}, {0, 0, 0}})) == alerts

    assert Alerts.Match.match(alerts, ie, DateTime.from({{2016, 6, 1}, {12, 0, 0}})) == []
    assert Alerts.Match.match(alerts, ie, DateTime.from({{2016, 6, 2}, {12, 0, 0}})) == []
  end
end
