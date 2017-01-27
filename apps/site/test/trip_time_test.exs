defmodule TripTimeTest do
  use ExUnit.Case, async: true
  alias Schedules.Schedule
  alias Predictions.Prediction

  @base_time  ~N[2017-01-02T12:00:00]

  @schedules [
    %Schedule{
      stop: %Schedules.Stop{id: "first"},
      time: @base_time 
    },
    %Schedule{
      stop: %Schedules.Stop{id: "second"},
      time: Timex.shift(@base_time, minutes: 10) 
    },
    %Schedule{
      stop: %Schedules.Stop{id: "third"},
      time: Timex.shift(@base_time, minutes: 20) 
    },
    %Schedule{
      stop: %Schedules.Stop{id: "fourthd"},
      time: Timex.shift(@base_time, minutes: 30) 
    },
    %Schedule{
      stop: %Schedules.Stop{id: "fifth"},
      time: Timex.shift(@base_time, minutes: 40) 
    },
    %Schedule{
      stop: %Schedules.Stop{id: "last"},
      time: Timex.shift(@base_time, minutes: 50) 
    }
  ]

  @predictions [
    %Prediction{
      stop_id: "first",
      time: Timex.shift(@base_time, minutes: 12) 
    },
    %Prediction{
      stop_id: "second",
      time: Timex.shift(@base_time, minutes: 22) 
    },
    %Prediction{
      stop_id: "third",
      time: Timex.shift(@base_time, minutes: 32) 
    }
  ]

  @non_matching_predictions [
    %Prediction{
      stop_id: "stop1",
      time: Timex.shift(@base_time, minutes: 12) 
    },
    %Prediction{
      stop_id: "stop2",
      time: Timex.shift(@base_time, minutes: 32) 
    }
  ]

  describe "build_times/2" do
    test "TripTimes are paired by stop" do
      trip_times = TripTime.build_times(@predictions, Enum.shuffle(@schedules))
      for %TripTime{schedule: schedule, prediction: prediction} <- Enum.take(trip_times, 3) do
        assert schedule.stop.id == prediction.stop_id
      end
    end

    test "All schedules are returned" do
      trip_times = TripTime.build_times(@predictions, @schedules)
      assert Enum.map(trip_times, & &1.schedule) == @schedules
    end

    test "Trip times are returned in order of ascending time" do
      trip_times = TripTime.build_times(Enum.shuffle(@predictions), Enum.shuffle(@schedules))
      assert Enum.map(trip_times, & &1.schedule) == @schedules
    end

    test "Predictions without matching stops are not returned" do
      trip_times = TripTime.build_times(@non_matching_predictions, Enum.shuffle(@schedules))
      for %TripTime{prediction: prediction} <- Enum.take(trip_times, 3) do
        refute prediction
      end
      assert Enum.map(trip_times, & &1.schedule) == @schedules
    end
  end
end
