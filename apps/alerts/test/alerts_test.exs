defmodule AlertsTest do
  use ExUnit.Case, async: true
  use Timex

  import Alerts.Alert
  alias Alerts.Alert

  describe "new/1" do
    test "with no params, returns a default struct" do
      assert new() == %Alert{}
    end

    test "with params, sets values (include informed_entity)" do
      entities = [%Alerts.InformedEntity{}]
      assert new(effect: :detour, informed_entity: entities) == %Alert{
        effect: :detour,
        informed_entity: Alerts.InformedEntitySet.new(entities)}
    end
  end

  describe "update/2" do
    test "updates an existing alert, keeping the old values" do
      alert = new(effect: :detour)
      entities = [%Alerts.InformedEntity{}]
      expected = new(effect: :detour, informed_entity: entities)
      actual = update(alert, informed_entity: entities)
      assert expected == actual
    end
  end

  describe "is_notice?/2" do
    test "Delay alerts are not notices" do
      delay = %Alert{effect: :delay}
      refute is_notice? delay, now()
    end

    test "Suspension alerts are not notices" do
      suspension = %Alert{effect: :suspension}
      refute is_notice? suspension, now()
    end

    test "Track Change is a notice" do
      change = %Alert{effect: :track_change}
      assert is_notice? change, now()
    end

    test "Minor Service Change is a notice" do
      change = %Alert{effect: :service_change, severity: 3}
      assert is_notice? change, now()
    end

    test "Current non-minor Service Change is an alert" do
      change = %Alert{effect: :service_change, active_period: [{Timex.shift(now(), days: -1), nil}]}
      refute is_notice? change, now()
    end

    test "Future non-minor Service Change is a notice" do
      change = %Alert{effect: :service_change, active_period: [{Timex.shift(now(), days: 5), nil}]}
      assert is_notice? change, now()
    end

    test "Shuttle is an alert if it's active and not Ongoing" do
      today = Timex.now("America/New_York")
      shuttle = %Alert{effect: :shuttle,
                       active_period: [{Timex.shift(today, days: -1), nil}],
                       lifecycle: :new}
      refute is_notice?(shuttle, today)
      assert is_notice?(shuttle, Timex.shift(today, days: -2))
    end

    test "Shuttle is a notice if it's Ongoing" do
      today = Timex.now("America/New_York")
      shuttle = %Alert{effect: :shuttle,
                       active_period: [{Timex.shift(today, days: -1), nil}],
                       lifecycle: :ongoing}
      assert is_notice? shuttle, now()
    end

    test "Non on-going alerts are notices if they arent happening now" do
      today = ~N[2017-01-01T12:00:00]
      tomorrow = Timex.shift(today, days: 1)
      shuttle = %Alert{effect: :shuttle,
                       active_period: [{tomorrow, nil}],
                       lifecycle: :upcoming}
      assert is_notice? shuttle, today
    end

    test "Cancellation is an alert if it's today" do
      # NOTE: this will fail around 11:55pm, since future will switch to a different day
      future = Timex.shift(now(), minutes: 5)
      cancellation = %Alert{effect: :cancellation,
                            active_period: [{future, future}],
                            lifecycle: :new}
      today = future |> DateTime.to_date
      yesterday = future |> Timex.shift(days: -1) |> DateTime.to_date
      refute is_notice? cancellation, today
      assert is_notice? cancellation, yesterday
    end
  end

  describe "human_effect/1" do
    test "returns a string representing the effect of the alert" do
      assert human_effect(%Alert{}) == "Unknown"
      assert human_effect(%Alert{effect: :snow_route}) == "Snow Route"
    end
  end

  describe "human_lifecycle/1" do
    test "returns a string representing the lifecycle of the alert" do
      assert human_lifecycle(%Alert{}) == "Unknown"
      assert human_lifecycle(%Alert{lifecycle: :new}) == "New"
      assert human_lifecycle(%Alert{lifecycle: :ongoing_upcoming}) == "Upcoming"
    end
  end

  defp now do
    Timex.now("America/New_York")
  end
end
