defmodule Site.AlertViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Site.AlertView

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

  test "test display_alert_effects returns one alert for one effect" do
    delay_alert = %Alerts.Alert{effect_name: "Delay"}

    expected = "Delay"
    actual = AlertView.display_alert_effects([delay_alert])

    assert expected == actual
  end

  test "display_alert_updated/1 returns the relative offset based on our timezone" do
    one_hour = Timex.shift(Util.now, hours: -1)
    alert = %Alerts.Alert{updated_at: one_hour}

    assert AlertView.display_alert_updated(alert) == "Updated 1 hour ago"
  end
  describe "newline_to_br/1" do
    test "escapes existing HTML" do
      expected = {:safe, "&lt;br&gt;"}
      actual = AlertView.newline_to_br("<br>")

      assert expected == actual
    end

    test "replaces newlines with breaks" do
      expected = {:safe, "hi<br />there"}
      actual = AlertView.newline_to_br("hi\nthere")

      assert expected == actual
    end

    test "combines multiple newlines" do
      expected = {:safe, "hi<br />there"}
      actual = AlertView.newline_to_br("hi\n\n\nthere")

      assert expected == actual
    end

    test "combines multiple Windows newlines" do
      expected = {:safe, "hi<br />there"}
      actual = AlertView.newline_to_br("hi\r\n\r\nthere")

      assert expected == actual
    end

    test "<strong>ifies a header" do
      expected = {:safe, "hi<hr><strong>Header:</strong><br />7:30"}
      actual = AlertView.newline_to_br("hi\nHeader:\n7:30")

      assert expected == actual
    end

    test "<strong>ifies a starting long header" do
      expected = {:safe, "<strong>Long Header:</strong><br />7:30"}
      actual = AlertView.newline_to_br("Long Header:\n7:30")

      assert expected == actual
    end
  end
end
