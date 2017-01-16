defmodule AlertsTest do
  use ExUnit.Case, async: true
  use Timex
  alias Alerts.Alert

  describe "is_notice?/2" do
    test "Delay alerts are not notices" do
      delay = %Alert{effect_name: "Delay"}
      refute Alert.is_notice? delay, now()
    end

    test "Suspension alerts are not notices" do
      suspension = %Alert{effect_name: "Suspension"}
      refute Alert.is_notice? suspension, now()
    end

    test "Track Change is a notice" do
      change = %Alert{effect_name: "Track Change"}
      assert Alert.is_notice? change, now()
    end

    test "Minor Service Change is a notice" do
      change = %Alert{effect_name: "Service Change", severity: "Minor"}
      assert Alert.is_notice? change, now()
    end

    test "Current non-minor Service Change is an alert" do
      change = %Alert{effect_name: "Service Change", active_period: [{Timex.shift(now(), days: -1), nil}]}
      refute Alert.is_notice? change, now()
    end

    test "Future non-minor Service Change is a notice" do
      change = %Alert{effect_name: "Service Change", active_period: [{Timex.shift(now(), days: 5), nil}]}
      assert Alert.is_notice? change, now()
    end

    test "Shuttle is an alert if it's active and not Ongoing" do
      today = Timex.now("America/New_York")
      shuttle = %Alert{effect_name: "Shuttle",
                       active_period: [{Timex.shift(today, days: -1), nil}],
                       lifecycle: "New"}
      refute Alert.is_notice?(shuttle, today)
      assert Alert.is_notice?(shuttle, Timex.shift(today, days: -2))
    end

    test "Shuttle is a notice if it's Ongoing" do
      today = Timex.now("America/New_York")
      shuttle = %Alert{effect_name: "Shuttle",
                       active_period: [{Timex.shift(today, days: -1), nil}],
                       lifecycle: "Ongoing"}
      assert Alert.is_notice? shuttle, now()
    end

    test "Cancellation is an alert if it's today" do
      # NOTE: this will fail around 11:55pm, since future will switch to a different day
      future = Timex.shift(now(), minutes: 5)
      cancellation = %Alert{effect_name: "Cancellation",
                            active_period: [{future, future}],
                            lifecycle: "New"}
      today = future |> DateTime.to_date
      yesterday = future |> Timex.shift(days: -1) |> DateTime.to_date
      refute Alert.is_notice? cancellation, today
      assert Alert.is_notice? cancellation, yesterday
    end
  end

  defp now do
    Timex.now("America/New_York")
  end
end
