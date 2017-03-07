defmodule PredictedSchedule.DisplayTest do
  use ExUnit.Case, async: true
  import PredictedSchedule.Display
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias Schedules.Schedule
  alias Predictions.Prediction
  alias Routes.Route

  describe "time/1" do
    @schedule_time ~N[2017-01-01T12:00:00]
    @prediction_time ~N[2018-02-02T14:14:14]
    @commuter_route %Route{id: "CR-Lowell", name: "Lowell", type: 2}

    test "Prediction is used if one is given" do
      display_time = time(%PredictedSchedule{schedule: %Schedule{time: @schedule_time}, prediction: %Prediction{time: @prediction_time}})
      assert safe_to_string(display_time) =~ "2:14PM"
      refute safe_to_string(display_time) =~ "12:00PM"
      assert safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Scheduled time is used if no prediction is available" do
      display_time = time(%PredictedSchedule{schedule: %Schedule{time: @schedule_time}, prediction: nil})
      assert safe_to_string(display_time) =~ "12:00PM"
      refute safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Empty string returned if no value available in predicted_schedule pair" do
      assert time(%PredictedSchedule{schedule: nil, prediction: nil}) == ""
    end

    test "prediction status is used if the prediction does not have a time" do
      display_time = time(
        %PredictedSchedule{
          schedule: nil,
          prediction: %Prediction{status: "Text status"}})
      assert safe_to_string(display_time) =~ "Text status"
      assert safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "if the scheduled and predicted times differ, cross out the scheduled one" do
      result = %PredictedSchedule{
        schedule: %Schedule{route: @commuter_route, time: @schedule_time},
        prediction: %Prediction{route: @commuter_route, time: @prediction_time}}
      |> time
      |> safe_to_string

      assert result =~ "12:00PM"
      assert result =~ "2:14PM"
      assert result =~ "fa fa-rss"
    end

    test "if the times do not differ, just returns the same result as a non-CR time" do
      result = %PredictedSchedule{
        schedule: %Schedule{route: @commuter_route, time: @schedule_time},
        prediction: %Prediction{route: @commuter_route, time: @schedule_time}}
        |> time
        |> safe_to_string

      assert result =~ "12:00P"
      assert result =~ "fa fa-rss"
    end

    test "handles nil schedules" do
      result = time(%PredictedSchedule{
            schedule: nil,
            prediction: %Prediction{route: @commuter_route, time: @prediction_time}})

      assert safe_to_string(result) =~ "2:14PM"
    end

    test "handles nil predictions" do
      result = time(%PredictedSchedule{
            schedule: %Schedule{time: @schedule_time},
            prediction: nil})

      assert safe_to_string(result) =~ "12:00PM"
    end
  end
end
