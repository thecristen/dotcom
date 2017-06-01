defmodule Alerts.PartitionTest do
  use ExUnit.Case, async: true

  alias Alerts.Alert
  import Alerts.Partition

  describe "current_and_upcoming/2" do
    @date ~D[2017-05-31]
    @date_time Timex.to_datetime(@date)
    @all_alerts [
      %Alert{id: "ongoing1", active_period: [{Timex.shift(@date_time, days: -1), Timex.shift(@date_time, days: 2)}]},
      %Alert{id: "ongoing2", active_period: [{nil, Timex.shift(@date_time, days: 5)}]},
      %Alert{id: "active", active_period: [{nil, nil}]},
      %Alert{id: "upcoming", active_period: [{Timex.shift(@date_time, days: 2), Timex.shift(@date_time, days: 5)}]}
    ]

    test "partitions current and upcoming alerts based on date" do
      {current, upcoming} = current_and_upcoming(@all_alerts, @date)

      assert Enum.map(current, & &1.id) == ["ongoing1", "ongoing2", "active"]
      assert Enum.map(upcoming, & &1.id) == ["upcoming"]
    end
  end
end
