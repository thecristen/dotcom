defmodule PredictedSchedule.DisplayTest do
  use ExUnit.Case, async: true
  import PredictedSchedule.Display
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias Schedules.Schedule
  alias Predictions.Prediction
  alias Routes.Route

  describe "time/1" do
    @early_time ~N[2017-01-01T12:00:00]
    @late_time ~N[2018-02-02T14:14:14]
    @commuter_route %Route{id: "CR-Lowell", name: "Lowell", type: 2}

    test "Prediction is used if one is given" do
      display_time = time(
        %PredictedSchedule{schedule: %Schedule{time: @early_time}, prediction: %Prediction{time: @late_time}})
      assert safe_to_string(display_time) =~ "2:14PM"
      refute safe_to_string(display_time) =~ "12:00PM"
      assert safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Scheduled time is used if no prediction is available" do
      display_time = time(%PredictedSchedule{schedule: %Schedule{time: @early_time}, prediction: nil})
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

    test "if the predicted time is later than the scheduled time, cross out the scheduled one" do
      result = %PredictedSchedule{
        schedule: %Schedule{route: @commuter_route, time: @early_time},
        prediction: %Prediction{route: @commuter_route, time: @late_time}}
      |> time
      |> safe_to_string

      assert result =~ "12:00PM"
      assert result =~ "2:14PM"
      assert result =~ "fa fa-rss"
    end

    test "if the predicted time is earlier than the scheduled time, cross out the scheduled one" do
      result = %PredictedSchedule{
        schedule: %Schedule{route: @commuter_route, time: @late_time},
        prediction: %Prediction{route: @commuter_route, time: @early_time}}
      |> time
      |> safe_to_string

      assert result =~ "2:14PM"
      assert result =~ "12:00PM"
      assert result =~ "fa fa-rss"
    end

    test "if the times do not differ, just returns the same result as a non-CR time" do
      result = %PredictedSchedule{
        schedule: %Schedule{route: @commuter_route, time: @early_time},
        prediction: %Prediction{route: @commuter_route, time: @early_time}}
        |> time
        |> safe_to_string

      assert result =~ "12:00P"
      assert result =~ "fa fa-rss"
    end

    test "if the trip is cancelled, only crosses out the schedule time" do
      result = %PredictedSchedule{
        schedule: %Schedule{route: @commuter_route, time: @early_time},
        prediction: %Prediction{route: @commuter_route, schedule_relationship: :cancelled}}
        |> time
        |> safe_to_string

      assert result =~ "<del"
      assert result =~ "12:00P"
      assert result =~ "fa fa-rss"
    end

    test "if a trip is skipped, crosses out the schedule time" do
      result = %PredictedSchedule{
        schedule: %Schedule{time: @early_time},
        prediction: %Prediction{schedule_relationship: :skipped}}
        |> time
        |> safe_to_string

      assert result =~ "<del"
      assert result =~ "12:00P"
      assert result =~ "fa fa-rss"
    end

    test "handles nil schedules" do
      result = time(%PredictedSchedule{
            schedule: nil,
            prediction: %Prediction{route: @commuter_route, time: @late_time}})

      assert safe_to_string(result) =~ "2:14PM"
    end

    test "handles nil predictions" do
      result = time(%PredictedSchedule{
            schedule: %Schedule{time: @early_time},
            prediction: nil})

      assert safe_to_string(result) =~ "12:00PM"
    end
  end

  describe "headsign/1" do
    test "if trip is present, displays the headsign from the trip" do
      trip = %Schedules.Trip{headsign: "headsign"}
      for {schedule, prediction} <- [
            {nil, %Prediction{trip: trip}},
            {%Schedule{trip: trip}, nil},
            {%Schedule{trip: trip}, %Prediction{trip: trip}}
          ] do
          ps = %PredictedSchedule{schedule: schedule, prediction: prediction}
          assert headsign(ps) == "headsign"
      end
    end

    test "if it's a westbound Green line without a trip, uses a hardcoded sign" do
      for {route_id, expected} <- %{
            "Green-B" => "Boston College",
            "Green-C" => "Cleveland Circle",
            "Green-D" => "Riverside",
            "Green-E" => "Heath Street"
                               } do
          route = %Routes.Route{id: route_id}
          prediction = %Prediction{direction_id: 0, route: route, trip: nil}
          ps = %PredictedSchedule{prediction: prediction}
          assert headsign(ps) == expected
      end
    end

    test "if the route/direction is anything else, returns an empty string" do
      for {route_id, direction_id} <- [
            {"Green-B", 1},
            {"Unknown", 0}
          ] do
          route = %Routes.Route{id: route_id}
          prediction = %Prediction{direction_id: direction_id, route: route, trip: nil}
          ps = %PredictedSchedule{prediction: prediction}
          assert headsign(ps) == ""
      end
    end

    test "if both schedule and prediction are nil, returns an empty string" do
      assert headsign(%PredictedSchedule{}) == ""
    end
  end

  describe "time_difference/1" do
    @base_time  ~N[2017-01-01T12:00:00]
    @schedule %Schedule{time: Timex.shift(@base_time, minutes: 30)}
    @prediction %Prediction{time: Timex.shift(@base_time, minutes: 28)}

    test "Prediction time is preferred" do
      ps = %PredictedSchedule{schedule: @schedule, prediction: @prediction}
      assert safe_to_string(time_difference(ps, @base_time)) =~ "28 mins"
    end

    test "Schedule used when no prediction" do
      ps = %PredictedSchedule{schedule: @schedule}
      output = time_difference(ps, @base_time)
      assert output =~ "30 mins"
      refute output =~ "fa-rss"
    end

    test "realtime icon shown when prediction is shown" do
      ps = %PredictedSchedule{schedule: @schedule, prediction: @prediction}
      assert safe_to_string(time_difference(ps, @base_time)) =~ "fa-rss"
    end

    test "Time shown when difference is over an hour" do
      ps = %PredictedSchedule{schedule: @schedule, prediction: %Prediction{time: Timex.shift(@base_time, hours: 2)}}
      assert safe_to_string(time_difference(ps, @base_time)) =~ "2:00PM"
    end

    test "Time shown as `< 1` minute when same time as current_time" do
      ps = %PredictedSchedule{schedule: %Schedule{time: @base_time}}
      assert time_difference(ps, @base_time) =~ "< 1 min"
    end
  end
end
