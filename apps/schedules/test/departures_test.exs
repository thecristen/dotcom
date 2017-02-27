defmodule Schedules.DeparturesTest do
  use ExUnit.Case, async: true

  alias Schedules.Departures
  alias Schedules.Schedule

  @time ~N[2017-02-28 12:00:00]
  @schedules [%Schedule{time: @time}, %Schedule{time: Timex.shift(@time, hours: 1)}, %Schedule{time: Timex.shift(@time, hours: 2)}]

  describe "first_and_last_departures/1" do
    test "returns the first and last departures of the day" do
      departures = Departures.first_and_last_departures(@schedules)
      assert departures.first_departure == List.first(@schedules).time
      assert departures.last_departure == List.last(@schedules).time
    end
  end

  describe "display_departures/1" do
    test "with no times, returns No Service" do
      result = Departures.display_departures(%Departures{first_departure: nil, last_departure: nil})
      assert result == "No Service"
    end

    test "with times, displays them formatted" do
      result = %Departures{
        first_departure: ~N[2017-02-27 06:15:00],
        last_departure: ~N[2017-02-28 01:04:00]
      }
      |> Departures.display_departures
      |> IO.iodata_to_binary

      assert result == "6:15AM-1:04AM"
    end
  end
end
