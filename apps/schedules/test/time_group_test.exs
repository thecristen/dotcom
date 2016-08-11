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
    for_all seconds in list(non_neg_integer) do
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

  test "frequency returns a single value if there's a single headway" do
    first_time = Timex.to_datetime({{2016, 1, 1}, {5, 26, 1}})
    first_schedule = %Schedule{time: first_time}
    second_time = Timex.to_datetime({{2016, 1, 1}, {5, 36, 1}})
    second_schedule = %Schedule{time: second_time}

    assert TimeGroup.frequency([@schedule, first_schedule, second_schedule]) == 10
  end

  test "frequency returns a min/max if there are different values" do
    first_time = Timex.to_datetime({{2016, 1, 1}, {5, 25, 1}})
    first_schedule = %Schedule{time: first_time}
    second_time = Timex.to_datetime({{2016, 1, 1}, {5, 36, 1}})
    second_schedule = %Schedule{time: second_time}

    assert TimeGroup.frequency([@schedule, first_schedule, second_schedule]) == {9, 11}
  end

  test "frequency returns nil if there's only one scheduled trip" do
    assert TimeGroup.frequency([@schedule]) == nil
  end
end
