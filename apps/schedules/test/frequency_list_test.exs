defmodule Schedules.FrequencyListTest do
  use ExUnit.Case, async: true

  alias Schedules.FrequencyList
  alias Schedules.Schedule

  @time ~N[2017-02-28 12:00:00]
  @schedules [%Schedule{time: @time}, %Schedule{time: Timex.shift(@time, hours: 1)}, %Schedule{time: Timex.shift(@time, hours: 2)}]

  describe "build_frequency_list/1" do
    test "first and last departures are returned with a FrequencyList" do
      frequency_list = FrequencyList.build_frequency_list(@schedules)
      assert frequency_list.departures.first_departure == List.first(@schedules).time
      assert frequency_list.departures.last_departure == List.last(@schedules).time
    end
  end
end
