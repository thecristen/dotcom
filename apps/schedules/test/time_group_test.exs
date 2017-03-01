defmodule TimeGroupTest do
  use ExUnit.Case, async: false
  use ExCheck
  use Timex
  alias Schedules.Schedule

  @time ~N[2016-01-01T05:16:01] |> Timex.to_datetime
  @schedule %Schedule{time: @time}

  test "by_group returns a keyword list of the schedules grouped by hour" do
    assert TimeGroup.by_hour([@schedule]) ==
      [{5, [@schedule]}]
  end

  test "keeps schedules in order between groups" do
    other_time = Timex.to_datetime({{2016, 1, 1}, {6, 50, 0}})
    other_schedule = %Schedule{time: other_time}
    assert TimeGroup.by_hour([@schedule, other_schedule]) ==
      [{5, [@schedule]}, {6, [other_schedule]}]
  end

  test "keeps schedules in order inside a group" do
    other_time = Timex.to_datetime({{2016, 1, 1}, {5, 50, 0}})
    other_schedule = %Schedule{time: other_time}
    assert TimeGroup.by_hour([@schedule, other_schedule]) ==
      [{5, [@schedule, other_schedule]}]
  end

  property "by_hour keeps schedules globally ordered" do
    for_all seconds in list(non_neg_integer()) do
      times = seconds
      |> Enum.map(fn seconds -> DateTime.from_unix!(seconds) end)

      schedules = times
      |> Enum.map(fn time -> %Schedule{time: time} end)

      groups = TimeGroup.by_hour(schedules)
      ungrouped = groups
      |> Enum.flat_map(fn {_, group} -> group end)

      schedules == ungrouped
    end
  end

  test "by_subway_period groups schedules into 5 groups" do
    # @schedule is am_rush
    midday = %Schedule{time: Timex.to_datetime({{2016, 1, 1}, {11, 0, 0}})}
    pm_rush = %Schedule{time: Timex.to_datetime({{2016, 1, 1}, {16, 0, 0}})}
    evening = %Schedule{time: Timex.to_datetime({{2016, 1, 1}, {19, 0, 0}})}
    late = %Schedule{time: Timex.to_datetime({{2016, 1, 2}, {1, 0, 0}})}
    assert TimeGroup.by_subway_period([@schedule, midday, pm_rush, evening, late]) == [
      am_rush: [@schedule],
      midday: [midday],
      pm_rush: [pm_rush],
      evening: [evening],
      late_night: [late]
    ]
  end

  test "frequency returns a min/max if there are different values" do
    first_time = Timex.to_datetime({{2016, 1, 1}, {5, 25, 1}})
    first_schedule = %Schedule{time: first_time}
    second_time = Timex.to_datetime({{2016, 1, 1}, {5, 36, 1}})
    second_schedule = %Schedule{time: second_time}

    assert TimeGroup.frequency([@schedule, first_schedule, second_schedule]) == {9, 11}
  end


  test "does not get a 0-minute headway if multiple trains have the same time" do
    first_time = Timex.to_datetime({{2016, 1, 1}, {5, 25, 1}})
    first_schedule = %Schedule{time: first_time}
    schedules = [@schedule, @schedule, first_schedule, first_schedule]

    {min, _max} = TimeGroup.frequency(schedules)
    refute min == 0
  end

  test "frequency returns nil if there's only one scheduled trip" do
    assert TimeGroup.frequency([@schedule]) == nil
    assert TimeGroup.frequency([@schedule, @schedule, @schedule]) == nil
  end

  describe "frequency_for_time/2" do
    test "gets a range of wait times for a stop during the am_rush" do
      first_time = Timex.to_datetime({{2016, 1, 1}, {5, 25, 1}})
      first_schedule = %Schedule{time: first_time}
      second_time = Timex.to_datetime({{2016, 1, 1}, {5, 36, 1}})
      second_schedule = %Schedule{time: second_time}
      schedules = [@schedule, first_schedule, second_schedule]

      assert TimeGroup.frequency_for_time(schedules, :am_rush) == %Schedules.Frequency{time_block: :am_rush, min_headway: 9, max_headway: 11}
    end

    test "gets an infinite frequency when there are no times during the given time" do
      first_time = Timex.to_datetime({{2016, 1, 1}, {5, 25, 1}})
      first_schedule = %Schedule{time: first_time}
      second_time = Timex.to_datetime({{2016, 1, 1}, {5, 36, 1}})
      second_schedule = %Schedule{time: second_time}
      schedules = [@schedule, first_schedule, second_schedule]

      assert TimeGroup.frequency_for_time(schedules, :midday) == %Schedules.Frequency{
        time_block: :midday,
        min_headway: :infinity,
        max_headway: :infinity
      }
    end
  end

  describe "frequency_by_time_block/1" do
    test "returns a list of frequency objects which cover the time ranges included in the schedules" do
      am_rush_time = Timex.to_datetime({{2016, 1, 1}, {5, 25, 1}})
      am_rush_schedule = %Schedule{time: am_rush_time}
      am_rush_time_2 = Timex.to_datetime({{2016, 1, 1}, {5, 36, 1}})
      am_rush_schedule_2 = %Schedule{time: am_rush_time_2}
      midday_time = Timex.to_datetime({{2016, 1, 1}, {9, 36, 1}})
      midday_schedule = %Schedule{time: midday_time}
      midday_time_2 = Timex.to_datetime({{2016, 1, 1}, {10, 36, 1}})
      midday_schedule_2 = %Schedule{time: midday_time_2}

      schedules = [am_rush_schedule, am_rush_schedule_2, midday_schedule, midday_schedule_2]

      assert TimeGroup.frequency_by_time_block(schedules) == [
        %Schedules.Frequency{time_block: :am_rush, min_headway: 11, max_headway: 11},
        %Schedules.Frequency{time_block: :midday, min_headway: 60, max_headway: 60},
        %Schedules.Frequency{time_block: :pm_rush},
        %Schedules.Frequency{time_block: :evening},
        %Schedules.Frequency{time_block: :late_night}
      ]
    end
  end

  describe "display_frequency_range/1" do
    test "when min headway and max headway are the same does not display both" do
      assert TimeGroup.display_frequency_range(%Schedules.Frequency{time_block: :am_rush, min_headway: 5, max_headway: 5}) == "5"
    end

    test "when min headway and max headway are different, displays the range" do
      assert TimeGroup.display_frequency_range(%Schedules.Frequency{time_block: :am_rush, min_headway: 2, max_headway: 5}) == ["2", "-", "5"]
    end
  end
end
