defmodule StopTimeTest do
  use ExUnit.Case, async: true

  alias Schedules.Schedule
  alias Predictions.Prediction

  @time ~N[2017-01-01T22:30:00]

  describe "StopTime.display_status/1" do
    test "returns the same as StopTime.display_status/2 with a nil second argument" do
      assert StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "On Time"}}) ==
              StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "On Time"}}, nil)
    end
  end

  describe "StopTime.display_status/2" do
    test "uses the departure status if it exists" do
      result = StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "On Time"}}, nil)

      assert IO.iodata_to_binary(result) == "On time"
    end

    test "includes track number if present" do
      result = StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "All Aboard", track: "5"}}, nil)

      assert IO.iodata_to_binary(result) == "All aboard on track 5"
    end

    test "returns a readable message if there's a difference between the scheduled and predicted times" do
      now = @time
      result =
        StopTime.display_status(
          %PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 5)}},
          %PredictedSchedule{schedule: nil, prediction: nil})

      assert IO.iodata_to_binary(result) == "Delayed 5 minutes"
    end

    test "returns the empty string if the predicted and scheduled times are the same" do
      now = @time
      result =
        StopTime.display_status(
          %PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: now}},
          %PredictedSchedule{schedule: nil, prediction: nil})

      assert IO.iodata_to_binary(result) == ""
    end

    test "takes the max of the departure and arrival time delays" do
      departure = @time
      arrival = Timex.shift(departure, minutes: 30)
      result =
        StopTime.display_status(
          %PredictedSchedule{schedule: %Schedule{time: departure}, prediction: %Prediction{time: Timex.shift(departure, minutes: 5)}},
          %PredictedSchedule{schedule: %Schedule{time: arrival}, prediction: %Prediction{time: Timex.shift(arrival, minutes: 10)}}
      )

      assert IO.iodata_to_binary(result) == "Delayed 10 minutes"
    end

    test "handles nil arrivals" do
      now = @time
      result =
        StopTime.display_status(
          %PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 5)}},
          nil)

      assert IO.iodata_to_binary(result) == "Delayed 5 minutes"
    end

    test "inflects the delay correctly" do
      now = @time
      result =
        StopTime.display_status(
          %PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 1)}},
          nil)

      assert IO.iodata_to_binary(result) == "Delayed 1 minute"
    end
  end

  describe "StopTime.delay/1" do
    test "returns the difference between a schedule and prediction" do
      now = @time

      assert StopTime.delay(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 14)}}) == 14
    end

    test "returns 0 if either time is nil, or if the argument itself is nil" do
      now = @time
      assert StopTime.delay(%PredictedSchedule{schedule: nil, prediction: %Prediction{time: Timex.shift(now, minutes: 14)}}) == 0
      assert StopTime.delay(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: nil}) == 0
      assert StopTime.delay(%PredictedSchedule{schedule: nil, prediction: nil}) == 0
      assert StopTime.delay(nil) == 0
    end
  end

  describe "StopTime.before/2" do
    test "compares by departures" do
      stop_time1 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T07:00:00]}}}
      stop_time2 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T08:00:00]}}}
      stop_time3 = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T09:00:00]}}}

      # 7:00 before 8:00
      assert StopTime.before?(stop_time1, stop_time2)

      # 7:00 before 9:00
      assert StopTime.before?(stop_time1, stop_time3)

      # 8:00 before 9:00
      assert StopTime.before?(stop_time2, stop_time3)

      # 8:00 before 8:00
      assert StopTime.before?(stop_time2, stop_time2)

      # refute 8:00 before 7:00
      refute StopTime.before?(stop_time2, stop_time1)

      # refute 9:00 before 7:00
      refute StopTime.before?(stop_time3, stop_time1)
    end

    test "compares by arrival when departure is nil" do
      stop_time1 =
        %StopTime{departure: nil,
                  arrival: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T10:00:00]}}}
      stop_time2 =
        %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T08:00:00]}},
                  arrival: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T11:00:00]}}}
      stop_time3 =
          %StopTime{departure: nil,
                    arrival: nil}

      # dep=nil; arr=10:00 before dep=8:00; arr=11:00
      assert StopTime.before?(stop_time1, stop_time2)
      refute StopTime.before?(stop_time2, stop_time1)

      # dep=nil; arr=nil before dep=nil; arr=10:00
      assert StopTime.before?(stop_time3, stop_time1)
      refute StopTime.before?(stop_time1, stop_time3)
    end

    test "compares when departure and arrival is nil" do
      dep_time_nil =
        %StopTime{departure: nil,
                  arrival: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T10:00:00]}}}
      arr_time_nil =
        %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T10:00:00]}},
                  arrival: nil}

      # dep=11; arr=nil before dep=nil; arr=10:00
      assert StopTime.before?(arr_time_nil, dep_time_nil)
      refute StopTime.before?(dep_time_nil, arr_time_nil)
    end
  end

  describe "StopTime.departure_schedule_before?/2" do
    test "compares with time" do
      stop_time = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T07:30:00]}}}

      assert StopTime.departure_schedule_before?(stop_time, ~N[2017-03-01T07:30:01])

      refute StopTime.departure_schedule_before?(stop_time, ~N[2017-03-01T07:29:00])

      refute StopTime.departure_schedule_before?(stop_time, ~N[2017-03-01T07:30:00])
    end
  end

  describe "StopTime.departure_schedule_after?/2" do
    test "compares with time" do
      stop_time = %StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: ~N[2017-03-01T07:30:00]}}}

      assert StopTime.departure_schedule_after?(stop_time, ~N[2017-03-01T07:29:00])

      refute StopTime.departure_schedule_after?(stop_time, ~N[2017-03-01T07:31:00])

      refute StopTime.departure_schedule_after?(stop_time, ~N[2017-03-01T07:30:00])
    end
  end
end
