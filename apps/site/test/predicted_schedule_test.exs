defmodule PredictedScheduleTest do
  use ExUnit.Case, async: true
  alias Schedules.{Schedule, Stop}
  alias Predictions.Prediction
  import PredictedSchedule

  @base_time  ~N[2017-01-02T12:00:00]

  @route %Routes.Route{id: "Teal"}

  @schedules [
    %Schedule{
      stop: %Stop{id: "first"},
      time: @base_time,
      route: @route
    },
    %Schedule{
      stop: %Stop{id: "second"},
      time: Timex.shift(@base_time, minutes: 10),
      route: @route
    },
    %Schedule{
      stop: %Stop{id: "third"},
      time: Timex.shift(@base_time, minutes: 20),
      route: @route
    },
    %Schedule{
      stop: %Stop{id: "fourth"},
      time: Timex.shift(@base_time, minutes: 30),
      route: @route
    },
    %Schedule{
      stop: %Stop{id: "fifth"},
      time: Timex.shift(@base_time, minutes: 40),
      route: @route
    },
    %Schedule{
      stop: %Stop{id: "last"},
      time: Timex.shift(@base_time, minutes: 50),
      route: @route
    }
  ]

  @predictions [
    %Prediction{
      stop: %Stop{id: "first"},
      time: Timex.shift(@base_time, minutes: 12),
      route: @route
    },
    %Prediction{
      stop: %Stop{id: "second"},
      time: Timex.shift(@base_time, minutes: 22),
      route: @route
    },
    %Prediction{
      stop: %Stop{id: "third"},
      time: Timex.shift(@base_time, minutes: 32),
      route: @route
    }
  ]

  @non_matching_predictions [
    %Prediction{
      stop: %Stop{id: "stop1"},
      time: Timex.shift(@base_time, minutes: 12)
    },
    %Prediction{
      stop: %Stop{id: "stop2"},
      time: Timex.shift(@base_time, minutes: 32)
    }
  ]

  describe "build_times/2" do
    test "PredictedSchedules are paired by stop" do
      predicted_schedules = group_by_trip(@predictions, Enum.shuffle(@schedules))
      for %PredictedSchedule{schedule: schedule, prediction: prediction} <- Enum.take(predicted_schedules, 3) do
        assert schedule.stop == prediction.stop
      end
    end

    test "All schedules are returned" do
      predicted_schedules = group_by_trip(@predictions, @schedules)
      assert Enum.map(predicted_schedules, & &1.schedule) == @schedules
    end

    test "PredictedSchedules are returned in order of ascending time" do
      predicted_schedules = group_by_trip(Enum.shuffle(@predictions), Enum.shuffle(@schedules))
      assert Enum.map(predicted_schedules, & &1.schedule) == @schedules
    end

    test "Predictions without matching stops are still returned" do
      predicted_schedules = group_by_trip(@non_matching_predictions, Enum.shuffle(@schedules))
      assert Enum.count(predicted_schedules) == Enum.count(@non_matching_predictions) + Enum.count(@schedules)
      for %PredictedSchedule{schedule: schedule, prediction: _prediction} <- Enum.take(predicted_schedules, 2) do
       refute schedule
      end
    end

    test "ScheduledPredictions are sorted with unmatched predictions first" do
      predicted_schedules = group_by_trip(@non_matching_predictions, Enum.shuffle(@schedules))
      for %PredictedSchedule{schedule: schedule, prediction: prediction} <- Enum.take(predicted_schedules, 2) do
       refute schedule
       assert prediction
      end

      for %PredictedSchedule{schedule: schedule, prediction: _prediction} <- Enum.drop(predicted_schedules, 2) do
       assert schedule
      end
    end
  end

  describe "stop/1" do
    test "Returns stop when schedule is available" do
      predicted_schedule = %PredictedSchedule{schedule: List.first(@schedules), prediction: List.first(@predictions)}
      assert stop(predicted_schedule).id == "first"
    end

    test "Returns stop when only prediction is available" do
      predicted_schedule = %PredictedSchedule{prediction: List.first(@predictions)}
      assert stop(predicted_schedule).id == "first"
    end
  end

  describe "route/1" do
    test "Returns route when schedule is available" do
      predicted_schedule = %PredictedSchedule{schedule: List.first(@schedules), prediction: List.first(@predictions)}
      assert route(predicted_schedule) == @route
    end

    test "Returns route when only prediction is available" do
      predicted_schedule = %PredictedSchedule{prediction: List.first(@predictions)}
      assert route(predicted_schedule) == @route
    end
  end

  describe "has_prediction?/1" do
    test "determines if PredictedSchedule has prediction" do
      with_prediction = %PredictedSchedule{schedule: List.first(@schedules), prediction: List.first(@predictions)}
      without_prediction = %PredictedSchedule{schedule: List.first(@schedules), prediction: nil}
      assert has_prediction?(with_prediction) == true
      assert has_prediction?(without_prediction) == false
    end
  end

  describe "time/1" do
    test "Scheduled time is given if one is available" do
      predicted_schedule = %PredictedSchedule{schedule: List.first(@schedules), prediction: List.last(@predictions)}
      assert time(predicted_schedule) == List.first(@schedules).time
    end
    test "Predicted time is used if no schedule present" do
      predicted_schedule = %PredictedSchedule{schedule: nil, prediction: List.last(@predictions)}
      assert time(predicted_schedule) == List.last(@predictions).time
    end
  end

  describe "direction_id/1" do
    test "uses prediction if available" do
      predicted_schedule = %PredictedSchedule{prediction: %Prediction{direction_id: 1}}
      assert direction_id(predicted_schedule) == 1
    end

    test "uses schedule's trip if there's no prediction" do
      predicted_schedule = %PredictedSchedule{schedule: %Schedule{trip: %Schedules.Trip{direction_id: 0}}}
      assert direction_id(predicted_schedule) == 0
    end
  end

  describe "map_optional/4" do
    test "returns nil if predicted_schedule is nil" do
      assert map_optional(nil, [:schedule], &is_nil/1) == nil
    end

    test "returns nil with an empty PredictedSchedule" do
      assert map_optional(%PredictedSchedule{}, [:schedule], &is_nil/1) == nil
    end

    test "can return a different default" do
      assert map_optional(nil, [:schedule], :default, &is_nil/1) == :default
    end

    test "returns the first valid value, mapped" do
      prediction = %PredictedSchedule{prediction: List.first(@predictions)}
      schedule = %PredictedSchedule{schedule: List.first(@schedules)}
      both = %PredictedSchedule{schedule: List.first(@schedules), prediction: List.first(@predictions)}

      assert map_optional(prediction, [:schedule, :prediction], & &1) == prediction.prediction
      assert map_optional(schedule, [:prediction, :schedule], & &1) == schedule.schedule
      assert map_optional(both, [:schedule, :prediction], & &1) == both.schedule
      assert map_optional(both, [:prediction, :schedule], & &1) == both.prediction
      assert map_optional(both, [:prediction, :schedule], & &1.__struct__) == Prediction
    end
  end

  describe "any_predictions?/1" do
    @scheduled_predictions [
      %PredictedSchedule{prediction: %Prediction{}},
      %PredictedSchedule{schedule: %Schedule{}, prediction: %Prediction{}},
      %PredictedSchedule{schedule: %Schedule{}}
    ]
    test "Determines if Trip info object has predictions" do
      assert TripInfo.any_predictions?(%TripInfo{sections: [@scheduled_predictions]})
      refute TripInfo.any_predictions?(%TripInfo{sections: [List.last(@scheduled_predictions)]})
    end
  end

  describe "delay/1" do
    @time ~N[2017-01-01T12:00:00]

    test "returns the difference between a schedule and prediction" do
      assert delay(%PredictedSchedule{schedule: %Schedule{time: @time}, prediction: %Prediction{time: Timex.shift(@time, minutes: 14)}}) == 14
    end

    test "returns 0 if either time is nil, or if the argument itself is nil" do
      assert delay(%PredictedSchedule{schedule: nil, prediction: %Prediction{time: Timex.shift(@time, minutes: 14)}}) == 0
      assert delay(%PredictedSchedule{schedule: %Schedule{time: @time}, prediction: nil}) == 0
      assert delay(%PredictedSchedule{schedule: nil, prediction: nil}) == 0
      assert delay(nil) == 0
    end
  end
end
