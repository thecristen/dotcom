defmodule AlertsTest do
  use ExUnit.Case
  use Timex
  alias Alerts.Alert

  describe "is_notice?/2" do
    test "Delay alerts are not notices" do
      delay = %Alert{effect_name: "Delay"}
      refute Alert.is_notice? delay
    end

    test "Track Change is a notice" do
      change = %Alert{effect_name: "Track Change"}
      assert Alert.is_notice? change
    end

    test "Shuttle is an alert if it's active and not Ongoing" do
      today = DateTime.now("America/New_York")
      shuttle = %Alert{effect_name: "Shuttle",
                       active_period: [{Timex.shift(today, days: -1), nil}],
                       lifecycle: "New"}
      refute Alert.is_notice?(shuttle, today)
      assert Alert.is_notice?(shuttle, Timex.shift(today, days: -2))
    end

    test "Shuttle is a notice if it's Ongoing" do
      today = DateTime.now("America/New_York")
      shuttle = %Alert{effect_name: "Shuttle",
                       active_period: [{Timex.shift(today, days: -1), nil}],
                       lifecycle: "Ongoing"}
      assert Alert.is_notice?(shuttle)
    end
  end
end
