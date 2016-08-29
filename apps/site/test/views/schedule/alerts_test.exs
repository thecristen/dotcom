defmodule Site.ScheduleView.AlertsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Site.ScheduleView

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

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
