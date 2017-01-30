defmodule PredictedScheduleTest do
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
    test "PredictedSchedules are paired by stop" do
      predicted_schedules = PredictedSchedule.group_by_trip(@predictions, Enum.shuffle(@schedules))
      for %PredictedSchedule{schedule: schedule, prediction: prediction} <- Enum.take(predicted_schedules, 3) do
        assert schedule.stop.id == prediction.stop_id
      end
    end

    test "All schedules are returned" do
      predicted_schedules = PredictedSchedule.group_by_trip(@predictions, @schedules)
      assert Enum.map(predicted_schedules, & &1.schedule) == @schedules
    end

    test "PredictedSchedules are returned in order of ascending time" do
      predicted_schedules = PredictedSchedule.group_by_trip(Enum.shuffle(@predictions), Enum.shuffle(@schedules))
      assert Enum.map(predicted_schedules, & &1.schedule) == @schedules
    end

    test "Predictions without matching stops are still returned" do
      predicted_schedules = PredictedSchedule.group_by_trip(@non_matching_predictions, Enum.shuffle(@schedules))
      assert Enum.count(predicted_schedules) == Enum.count(@non_matching_predictions) + Enum.count(@schedules)
      for %PredictedSchedule{schedule: schedule, prediction: _prediction} <- Enum.take(predicted_schedules, 2) do
       refute schedule
      end
    end

    test "ScheduledPredictions are sorted with unmatched predictions first" do
      predicted_schedules = PredictedSchedule.group_by_trip(@non_matching_predictions, Enum.shuffle(@schedules))
      for %PredictedSchedule{schedule: schedule, prediction: prediction} <- Enum.take(predicted_schedules, 2) do
       refute schedule
       assert prediction
      end

      for %PredictedSchedule{schedule: schedule, prediction: _prediction} <- Enum.drop(predicted_schedules, 2) do
       assert schedule
      end
    end
  end

  describe "stop_id/1" do
    test "Returns stop_id when schedule is available" do
      predicted_schedule = %PredictedSchedule{schedule: List.first(@schedules), prediction: List.first(@predictions)}
      assert PredictedSchedule.stop_id(predicted_schedule) == "first"
    end

    test "Returns stop_id when only prediction is available" do
      predicted_schedule = %PredictedSchedule{prediction: List.first(@predictions)}
      assert PredictedSchedule.stop_id(predicted_schedule) == "first"
    end
  end
end
