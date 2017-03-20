defmodule StopTimeListFilterTest do
  use ExUnit.Case, async: true
  import StopTime.Filter

  alias Schedules.Schedule
  alias Predictions.Prediction

  describe "StopTime.find_max_earlier_departure_schedule_time/2" do
    test "finds max earlier departure time" do
      stop_time1 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T07:00:00]}}}
      stop_time2 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T08:00:00]}}}
      stop_time3 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T09:00:00]}}}


      # [ 7:00, 8:00, 9:00 ] @ 8:10 -> 8:00
      assert find_max_earlier_departure_schedule_time([stop_time1, stop_time2, stop_time3], ~N[2017-03-01T08:10:00]) == ~N[2017-03-01T08:00:00]

      # [ 7:00, 8:00, 9:00 ] @ 9:10 -> nil since the current time is after the last time
      assert find_max_earlier_departure_schedule_time([stop_time1, stop_time2, stop_time3], ~N[2017-03-01T09:10:00]) == nil

      # [ 7:00, 8:00, 9:00 ] @ 7:00 -> 7:00
      assert find_max_earlier_departure_schedule_time([stop_time1, stop_time2, stop_time3], ~N[2017-03-01T07:00:00]) == ~N[2017-03-01T07:00:00]

      # [ 7:00, 8:00, 9:00 ] @ 6:59 -> nil
      assert find_max_earlier_departure_schedule_time([stop_time1, stop_time2, stop_time3], ~N[2017-03-01T06:59:00]) == nil

    end
  end

  describe "StopTime.remove_departure_schedules_before/2" do
    test "removes stop_times" do
      stop_time1 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T07:00:00]}}}
      stop_time2 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T08:00:00]}}}
      stop_time3 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T09:00:00]}}}

      # [ 7:00, 8:00, 9:00 ] before 8:10 -> [ 8:00, 9:00 ]
      result1 = remove_departure_schedules_before([stop_time1, stop_time2, stop_time3], ~N[2017-03-01T07:10:00])
      assert result1 == [ stop_time2, stop_time3 ]

      # [ 9:00, 8:00, 7:00 ] before 8:10 -> [ 9:00, 8:00 ]
      result2 = remove_departure_schedules_before([stop_time3, stop_time2, stop_time1], ~N[2017-03-01T07:10:00])
      assert result2 == [ stop_time3, stop_time2 ]

      # [ 9:00, 8:00, 7:00 ] before nil -> [ 7:00, 8:00, 9:00 ]
      result3 = remove_departure_schedules_before([stop_time1, stop_time2, stop_time3], nil)
      assert result3 == [ stop_time1, stop_time2, stop_time3 ]
    end
  end

  describe "StopTime.filter/3" do
    test "filters last trip and upcoming" do
      stop_time1 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T07:00:00]}}}
      stop_time2 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T08:00:00]}}}
      stop_time3 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T09:00:00]}}}

      # [ 7:00, 8:00, 9:00 ] @ 7:10 -> [ 7:00, 8:00, 9:00 ]
      result1 = filter([stop_time1, stop_time2, stop_time3], :last_trip_and_upcoming, ~N[2017-03-01T07:10:00])
      assert result1 == [ stop_time1, stop_time2, stop_time3 ]

      # [ 9:00, 8:00, 7:00 ] @ 8:10 -> [ 9:00, 8:00 ]
      result2 = filter([stop_time3, stop_time2, stop_time1], :last_trip_and_upcoming, ~N[2017-03-01T08:10:00])
      assert result2 == [ stop_time3, stop_time2 ]

      # [ 9:00, 8:00, 7:00 ] @ 8:10 the day before -> [ 9:00, 8:00, 7:00 ]
      result2 = filter([stop_time3, stop_time2, stop_time1], :last_trip_and_upcoming, ~N[2017-02-28T08:10:00])
      assert result2 == [ stop_time3, stop_time2, stop_time1 ]

      # [ 9:00, 8:00, 7:00 ] @ 8:10 the next day -> [ 9:00, 8:00, 7:00 ]
      result3 = filter([stop_time3, stop_time2, stop_time1], :last_trip_and_upcoming, ~N[2017-03-02T08:10:00])
      assert result3 == [ stop_time3, stop_time2, stop_time1 ]
    end


    test "filters trips with no departure schedule" do
      # { nil -- 10:00(p) }
      stop_time1 =
        %StopTime{
          departure: %PredictedSchedule{schedule: nil, prediction: nil},
          arrival: %PredictedSchedule{schedule: nil, prediction: %Schedule{time: ~N[2017-03-01T10:00:00]}}}

      # { 9:00(s) 9:00(p) -- 11:00(p) }
      stop_time2 =
        %StopTime{
          departure:
            %PredictedSchedule{
              schedule: %Schedule{time: ~N[2017-03-01T09:00:00]},
              prediction: %Prediction{time: ~N[2017-03-01T09:00:00]}},
          arrival:
            %PredictedSchedule{
              schedule: nil,
              prediction: %Schedule{time: ~N[2017-03-01T11:00:00]}}}

      # [ { nil -- 10:00(p), { 9:00(s) 9:00(p) -- 11:00(p) } ] @ 10:30 -> [ { nil -- 10:00(p), { 9:00(s) 9:00(p) -- 11:00(p) } ]
      assert filter([stop_time1, stop_time2], :last_trip_and_upcoming, ~N[2017-03-01T10:00:00]) == [ stop_time1, stop_time2 ]
    end

  end

  describe "StopTime.expansion/3" do
    @times List.duplicate(%StopTime{}, 6)

    test "Expansion is none when there are no more times to show" do
      assert expansion(@times, @times, true) == :none
      assert expansion(@times, @times, false) == :none
    end

    test "Expansion is :collapsed when more times can be shown" do
      assert expansion(@times, Enum.take(@times, 3), false) == :collapsed
    end

    test "Expansion is :expanded when filtered times can be shown" do
      assert expansion(@times, Enum.take(@times, 3), true) == :expanded
    end
  end
end
