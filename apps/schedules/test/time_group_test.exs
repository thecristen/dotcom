defmodule TimeGroupTest do
  use ExUnit.Case, async: false
  use ExCheck
  use Timex
  alias Schedules.Schedule

  @time DateTime.from_erl({{2016, 1, 1}, {5, 16, 1}})
  @schedule %Schedule{time: @time}

  test "by_group returns a keyword list of the schedules grouped by hour" do
    assert TimeGroup.by_hour([@schedule]) ==
      [{5, [@schedule]}]
  end

  test "keeps schedules in order between groups" do
    other_time = DateTime.from_erl({{2016, 1, 1}, {6, 50, 0}})
    other_schedule = %Schedule{time: other_time}
    assert TimeGroup.by_hour([@schedule, other_schedule]) ==
      [{5, [@schedule]}, {6, [other_schedule]}]
  end

  test "keeps schedules in order inside a group" do
    other_time = DateTime.from_erl({{2016, 1, 1}, {5, 50, 0}})
    other_schedule = %Schedule{time: other_time}
    assert TimeGroup.by_hour([@schedule, other_schedule]) ==
      [{5, [@schedule, other_schedule]}]
  end

  property "by_hour keeps schedules globally ordered" do
    for_all seconds in list(non_neg_integer) do
      times = seconds
      |> Enum.map(fn seconds -> DateTime.from_seconds(seconds) end)

      schedules = times
      |> Enum.map(fn time -> %Schedule{time: time} end)

      groups = TimeGroup.by_hour(schedules)
      ungrouped = groups
      |> Enum.flat_map(fn {_, group} -> group end)

      schedules == ungrouped
    end
  end
end
