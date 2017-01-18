defmodule Site.ScheduleV2.BusViewTest do
  use Site.ConnCase, async: true

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}
  import Site.ScheduleV2.BusView
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "display_direction/1" do
    test "given no schedules, returns no content" do
      assert display_direction([]) == ""
    end

    test "given a non-empty list of schedules, displays the direction of the first schedule's route" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}}
      trip = %Trip{direction_id: 1}
      schedules = [
        %Schedules.Schedule{route: route, trip: trip}
      ]
      assert schedules |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end

  describe "merge_predictions_and_schedules/2" do
    test "deduplicates departures by trip ID" do
      now = Util.now
      predictions = for trip_id <- 0..4 do
        %Prediction{time: now, trip: %Trip{id: trip_id}}
      end
      schedules = for trip_id <- 3..6 do
        %Schedule{time: now, trip: %Trip{id: trip_id}}
      end
      merged = merge_predictions_and_schedules(predictions, schedules)
      assert merged |> Enum.uniq_by(& &1.trip.id) == merged
    end

    test "sorts departures by time" do
      now = Util.now
      predictions = for offset <- 0..2 do
        %Prediction{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      schedules = for offset <- 3..5 do
        %Schedule{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      merged = merge_predictions_and_schedules(predictions, schedules)
      assert merged |> Enum.sort_by(& &1.time) == merged
    end

    test "with no predictions, shows all schedules" do
      now = Util.now
      schedules = for trip_id <- 0..5 do
        %Schedule{time: now, trip: %Trip{id: trip_id}}
      end
      merged = merge_predictions_and_schedules([], schedules)
      assert merged == schedules
    end

    test "shows predicted departures first, then scheduled departures" do
      now = Util.now
      predictions = for offset <- [1, 3] do
        %Prediction{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      schedules = for offset <- [0, 2, 4] do
        %Schedule{time: now |> Timex.shift(minutes: offset), trip: %Trip{id: offset}}
      end
      merged = merge_predictions_and_schedules(predictions, schedules)
      assert merged == List.flatten [predictions, List.last(schedules)]
    end
  end

  describe "display_scheduled_prediction/1" do
    @schedule_time Timex.now
    @prediction_time Timex.shift(@schedule_time, hours: 1)

    test "Prediction is used if one is given" do
      display_time = display_scheduled_prediction({%Schedule{time: @schedule_time}, %Prediction{time: @prediction_time}})
      assert safe_to_string(display_time) =~ Site.ViewHelpers.format_schedule_time(@prediction_time)
      assert safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Scheduled time is used if no prediction is available" do
      display_time = display_scheduled_prediction({%Schedule{time: @schedule_time}, nil})
      assert safe_to_string(display_time) =~ Site.ViewHelpers.format_schedule_time(@schedule_time)
      refute safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Empty string returned if no value available in predicted_schedule pair" do
      assert display_scheduled_prediction({nil, nil}) == ""
    end
  end

  describe "group_trips/4" do
    @schedule_time Timex.now
    @prediction_time Timex.shift(@schedule_time, hours: 1)
    @origin "origin"
    @dest "dest"

    @trip1 %Trip{id: 1}
    @trip2 %Trip{id: 2}
    @trip3 %Trip{id: 3}
    @trip4 %Trip{id: 4}

    @schedule_pair1 {%Schedule{trip: @trip1, time: @schedule_time}, %Schedule{trip: @trip1, time: @prediction_time}}
    @schedule_pair2 {%Schedule{trip: @trip2, time: @schedule_time}, %Schedule{trip: @trip2, time: @prediction_time}}
    @schedule_pair3 {%Schedule{trip: @trip3, time: @schedule_time}, %Schedule{trip: @trip3, time: @prediction_time}}
    @schedule_pair4 {%Schedule{trip: @trip4, time: @schedule_time}, %Schedule{trip: @trip4, time: @prediction_time}}

    @origin_prediction1 %Prediction{trip: @trip1, stop_id: @origin, time: @prediction_time}
    @dest_prediction1 %Prediction{trip: @trip1, stop_id: @dest, time: @prediction_time}
    @origin_prediction2 %Prediction{trip: @trip2, stop_id: @origin, time: @prediction_time}
    @dest_prediction2 %Prediction{trip: @trip2, stop_id: @dest, time: @prediction_time}
    @dest_prediction4 %Prediction{trip: @trip4, stop_id: @dest, time: @prediction_time}

    test "Predictions are shown if there are no corresponding schedules" do
      trips = group_trips([@schedule_pair3], [@origin_prediction1, @dest_prediction1, @dest_prediction2], @origin, @dest)
      assert Enum.count(trips) == 3
      assert match?({{nil, _prediction}, {nil, _prediction2}}, List.first(trips))
      assert match?({{_departure, nil}, {_arrival, nil}}, List.last(trips))
    end

    test "Predictions are shown first" do
      schedules = [@schedule_pair1, @schedule_pair2, @schedule_pair3]
      predictions = [@origin_prediction1, @dest_prediction1, @dest_prediction2, @origin_prediction2]
      trips = group_trips(schedules, predictions, @origin, @dest)

      predicted_schedules = Enum.take_while(trips, &prediction?/1)
      assert Enum.count(predicted_schedules) == 2
    end

    test "scheduled_predictions are shown in the order: Predicted arrivals without departures, predictions, schedules" do
      schedules = [@schedule_pair2, @schedule_pair3, @schedule_pair4]
      predictions = [@dest_prediction1, @origin_prediction2, @dest_prediction4]
      trips = group_trips(schedules, predictions, @origin, @dest)

      assert {{nil, nil}, {nil, %Prediction{trip: @trip1}}} = Enum.at(trips, 0)
      assert {{%Schedule{trip: @trip2}, %Prediction{trip: @trip2}}, {_arrival, nil}} = Enum.at(trips, 1)
      assert {{%Schedule{trip: @trip4}, nil}, {_arrival, %Prediction{trip: @trip4}}} = Enum.at(trips, 2)
      assert {{%Schedule{trip: @trip3}, nil}, {%Schedule{trip: @trip3}, nil}} = Enum.at(trips, 3)
    end

    test "Predictions are paired by origin and destination" do
      schedules = [@schedule_pair1, @schedule_pair2]
      predictions = [@origin_prediction1, @dest_prediction1, @dest_prediction2, @origin_prediction2]
      trips = group_trips(schedules, predictions, @origin, @dest)

      for {{_departure, departure_prediction}, {_arrival, arrival_prediction}} <- trips do
        assert departure_prediction.stop_id == @origin
        assert arrival_prediction.stop_id == @dest
      end
    end
  end

  describe "get_valid_trip/1" do
    test "Returns a trip id" do
      schedule = %Schedule{trip: %Trip{id: "1"}}
      prediction = %Prediction{trip: %Trip{id: "8"}}

      schedule_pair1 = {{nil, prediction}, {nil, nil}}
      schedule_pair2 = {{nil, nil}, {nil, prediction}}
      schedule_pair3 = {{schedule, nil}, {schedule, nil}}

      assert get_valid_trip(schedule_pair1) == "8"
      assert get_valid_trip(schedule_pair2) == "8"
      assert get_valid_trip(schedule_pair3) == "1"
    end
  end

  defp prediction?({{_, nil}, {_, nil}}), do: false
  defp prediction?(_), do: true
end
