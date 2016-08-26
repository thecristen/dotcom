defmodule Site.ScheduleView.AlertsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Site.ScheduleView

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

  describe "has_alerts?/2" do
    test "returns false if the only alert affects the whole route" do
      all_rail_alert = %Alerts.Alert{informed_entity: [%Alerts.InformedEntity{route_type: @route.type}]}
      all_line_alert = %Alerts.Alert{informed_entity: [%Alerts.InformedEntity{route_type: @route.type, route: @route.id}]}

      refute ScheduleView.Alerts.has_alerts?([all_rail_alert, all_line_alert], @schedule)
    end

    test "returns true if the alert affects the whole route and is a delay" do
      all_line_delay = %Alerts.Alert{
        effect_name: "Delay",
        informed_entity: [%Alerts.InformedEntity{route_type: @route.type, route: @route.id}]}

      assert ScheduleView.Alerts.has_alerts?([all_line_delay], @schedule)
    end

    test "returns true if there's an alert for the trip" do
      trip_alert = %Alerts.Alert{effect_name: "Delay", informed_entity: [%Alerts.InformedEntity{trip: @trip.id}]}

      assert ScheduleView.Alerts.has_alerts?([trip_alert], @schedule)
    end
  end

  test "test display_alert_effects returns one alert for one effect" do
    delay_alert = %Alerts.Alert{effect_name: "Delay"}

    expected = "Delay"
    actual = ScheduleView.Alerts.display_alert_effects([delay_alert])

    assert expected == actual
  end

  test "display_alert_updated/1 returns the relative offset based on our timezone" do
    one_hour = Timex.shift(Util.now, hours: -1)
    alert = %Alerts.Alert{updated_at: one_hour}

    assert ScheduleView.Alerts.display_alert_updated(alert) == "Updated 1 hour ago"
  end
end
