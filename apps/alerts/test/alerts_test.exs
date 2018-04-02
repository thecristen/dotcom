defmodule AlertsTest do
  use ExUnit.Case, async: true
  use Timex

  import Alerts.Alert
  alias Alerts.Alert

  @now Util.to_local_time(~N[2018-01-15T12:00:00])

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

  describe "all_types/0" do
    test "contains no duplicates" do
      assert Enum.uniq(all_types()) == all_types()
    end
  end

  test "within_one_week/2" do
    assert within_one_week(~N[2018-01-01T12:00:00], ~N[2018-01-08T12:00:00]) == false
    assert within_one_week(~N[2018-01-08T12:00:00], ~N[2018-01-01T12:00:00]) == false
    assert within_one_week(~N[2018-01-01T12:00:00], ~N[2018-01-07T11:59:00]) == true
    assert within_one_week(~N[2018-01-07T11:59:00], ~N[2018-01-01T12:00:00]) == true
  end

  describe "is_urgent_period?/3" do
    test "severe alerts within 1 week of end date are urgent" do
      alert = %Alert{severity: 7}
      now = ~N[2018-01-15T12:00:00] |> Util.to_local_time()
      start_date = Timex.shift(now, days: -10)
      end_date = Timex.shift(now, days: 6)
      assert is_urgent_period?({nil, end_date}, alert, now) == true
      assert is_urgent_period?({start_date, end_date}, alert, now) == true
    end

    test "severe alerts beyond 1 week of end date are not urgent" do
      alert = %Alert{severity: 7}
      now = ~N[2018-01-15T12:00:00] |> Util.to_local_time()
      start_date = Timex.shift(now, days: -10)
      end_date = Timex.shift(now, days: 14)
      assert is_urgent_period?({nil, end_date}, alert, now) == false
      assert is_urgent_period?({start_date, end_date}, alert, now) == false
    end

    test "severe alerts within 1 week of start date are urgent" do
      alert = %Alert{severity: 7}
      now = ~N[2018-01-15T12:00:00] |> Util.to_local_time()
      start_date = Timex.shift(now, days: -6)
      end_date = Timex.shift(now, days: 10)
      assert is_urgent_period?({start_date, nil}, alert, now) == true
      assert is_urgent_period?({start_date, end_date}, alert, now) == true
    end

    test "severe alerts beyond 1 week of start date are not urgent" do
      alert = %Alert{severity: 7}
      now = ~N[2018-01-15T12:00:00] |> Util.to_local_time()
      start_date = Timex.shift(now, days: -14)
      end_date = Timex.shift(now, days: 10)
      assert is_urgent_period?({start_date, nil}, alert, now) == false
      assert is_urgent_period?({start_date, end_date}, alert, now) == false
    end
  end

  describe "is_urgent_alert?/2" do
    test "alerts below level 7 are never urgent" do
      for type <- all_types() do
        result = {type, is_urgent_alert?(%Alert{effect: type, severity: 6}, @now)}
        assert result == {type, false}
      end
    end

    test "severe alert with no active period is always urgent regardless of update time" do
      for type <- all_types() do
        result = {type, is_urgent_alert?(%Alert{effect: type, severity: 7,
                                                updated_at: Timex.shift(@now, days: -30)}, @now)}
        assert result == {type, true}
      end
    end

    test "severe alert with active period is urgent if updated within the last week" do
      for type <- all_types() do
        alert = %Alert{effect: type, severity: 7, updated_at: Timex.shift(@now, days: -6)}
        assert {type, is_urgent_alert?(alert, @now)} == {type, true}
      end
    end
  end

  describe "is_notice?/2" do
    def types_which_can_be_notices do
      all_types()
      |> List.delete(:delay)
      |> List.delete(:suspension)
    end

    test "Delay alerts are not notices" do
      delay = %Alert{effect: :delay}
      refute is_notice? delay, @now
    end

    test "Suspension alerts are not notices" do
      suspension = %Alert{effect: :suspension}
      refute is_notice? suspension, @now
    end

    test "severe alerts updated within the last week are always an alert" do
      updated = Timex.shift(@now, days: -6, hours: -23)
      period_start = Timex.shift(@now, days: -8)
      period_end = Timex.shift(@now, days: 8)
      assert within_one_week(@now, updated) == true
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type,
                       severity: 7,
                       updated_at: updated,
                       active_period: [{period_start, period_end}]}
        assert {type, is_notice?(alert, @now)} == {type, false}
        assert {type, is_notice?(%{alert | active_period: [{nil, period_end}]}, @now)} == {type, false}
        assert {type, is_notice?(%{alert | active_period: [{period_start, nil}]}, @now)} == {type, false}
      end
    end

    test "severe alerts not updated in the last week are an alert within a week of the start date" do
      updated = Timex.shift(@now, days: -10)
      period_start = Timex.shift(@now, days: -5)
      period_end = Timex.shift(@now, days: 15)
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type,
                       severity: 7,
                       updated_at: updated,
                       active_period: [{period_start, period_end}]}
        assert {type, is_notice?(alert, @now)} == {type, false}
      end
    end

    test "severe alerts not updated in the last week are an alert within a week of the end date" do
      updated = Timex.shift(@now, days: -8)
      period_start = Timex.shift(@now, days: -20)
      period_end = Timex.shift(@now, days: 6)
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type,
                       severity: 7,
                       updated_at: updated,
                       active_period: [{period_start, period_end}]}
        assert {type, is_notice?(alert, @now)} == {type, false}
      end
    end

    test "severe alerts are an alert if within first week of active period (nil alert end date)" do
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type,
                       severity: 7,
                       updated_at: Timex.shift(now(), days: -7, hours: -1),
                       active_period: [{Timex.shift(now(), days: -6, hours: -23), nil}]
                      }
        assert {type, is_notice?(alert, now())} == {type, false}
      end
    end

    test "severe alerts are an alert if within last week of active period" do
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type,
                       severity: 7,
                       updated_at: Timex.shift(now(), days: -7, hours: -1),
                       active_period: [{Timex.shift(now(), days: -14), Timex.shift(now(), days: 6, hours: 23)}]
                      }
        assert {type, is_notice?(alert, now())} == {type, false}
      end
    end

    test "severe alerts are an alert if within last week of active period (nil alert start date)" do
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type,
                       severity: 7,
                       updated_at: Timex.shift(now(), days: -7, hours: -1),
                       active_period: [{nil, Timex.shift(now(), days: 6, hours: 23)}]
                      }
        assert {type, is_notice?(alert, now())} == {type, false}
      end
    end

    test "severe alerts not within a week of start or end date are a notice" do
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type,
                       severity: 7,
                       updated_at: Timex.shift(now(), days: -7, hours: -1),
                       active_period: [{Timex.shift(now(), days: -7, hours: -1), Timex.shift(now(), days: 7, hours: 1)}]
                      }
        assert {type, is_notice?(alert, now())} == {type, true}
      end
    end

    test "severe alerts not within a week of start or end date are an alert if updated in the last week" do
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type, severity: 7,
                       updated_at: Timex.shift(now(), days: -6, hours: -23),
                       active_period: [{Timex.shift(now(), days: -7, hours: -1),
                                        Timex.shift(now(), days: 7, hours: 1)}]}
        assert {type, is_notice?(alert, now())} == {type, false}
      end
    end

    test "one active_period meeting criteria for making it not a notice will result in not a notice" do
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type, severity: 7,
                       updated_at: Timex.shift(now(), days: -6, hours: -1),
                       active_period: [{Timex.shift(now(), days: -7, hours: -1),
                                        Timex.shift(now(), days: 7, hours: 1)},
                                       {Timex.shift(now(), days: -6, hours: -23),
                                        Timex.shift(now(), days: 6, hours: 23)}]}
        assert {type, is_notice?(alert, now())} == {type, false}
      end
    end

    test "all active_periods meeting criteria for making it a notice will result in a notice" do
      for type <- types_which_can_be_notices() do
        alert = %Alert{effect: type, severity: 7,
                       updated_at: Timex.shift(now(), days: -7, hours: -1),
                       active_period: [{Timex.shift(now(), days: -7, hours: -1),
                                        Timex.shift(now(), days: 7, hours: 1)},
                                       {Timex.shift(now(), days: -10, hours: -23),
                                        Timex.shift(now(), days: 10, hours: 23)}]}
        assert {type, is_notice?(alert, now())} == {type, true}
      end
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

    test "Cancellation with multiple periods are notices if today is within on of the periods" do
      # NOTE: this will fail around 11:55pm, since future will switch to a different day
      future = Timex.shift(now(), minutes: 5)
      today = future |> DateTime.to_date
      yesterday = future |> Timex.shift(days: -1) |> DateTime.to_date
      tomorrow = future |> Timex.shift(days: 1) |> DateTime.to_date
      cancellation = %Alert{effect: :cancellation,
                            active_period: [{future, future}, {tomorrow, tomorrow}],
                            lifecycle: :new}
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
