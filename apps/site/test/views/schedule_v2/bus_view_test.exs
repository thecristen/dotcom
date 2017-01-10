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

  describe "display_time/2" do
    test "Prediction is used if one is given" do
      prediction_time = Timex.parse!("Tue, 05 Mar 2013 23:25:19 Z", "{RFC1123z}")
      prediction = %Prediction{time: prediction_time}
      scheduled = %Schedule{time: Timex.parse!("Tue, 05 Mar 2013 11:02:19 Z", "{RFC1123z}")}
      actual = safe_to_string(display_time(scheduled, prediction))

      assert actual =~ Timex.format!(prediction_time, "{0h12}:{m}{AM}")
      assert actual =~ "fa fa-rss"
    end

    test "Scheduled time is used if no prediction is available" do
      scheduled_time = Timex.parse!("Tue, 05 Mar 2013 23:25:19 Z", "{RFC1123z}")
      scheduled = %Schedule{time: scheduled_time}
      actual = safe_to_string(display_time(scheduled, nil))

      assert actual =~ Timex.format!(scheduled_time, "{0h12}:{m}{AM}")
      refute actual =~ "fa fa-rss"
    end
  end

  describe "group_trips/3" do
    @trip0  %Trip{id: 0}
    @trip1  %Trip{id: 1}
    @trip2  %Trip{id: 2}
    @time Timex.now()

    @schedule_pair0  {%Schedule{time: @time, trip: @trip0}, %Schedule{time: @time, trip: @trip0}}
    @schedule_pair1  {%Schedule{time: @time, trip: @trip1}, %Schedule{time: @time, trip: @trip1}}
    @schedule_pair2  {%Schedule{time: @time, trip: @trip2}, %Schedule{time: @time, trip: @trip2}}
    test "schedules are grouped by trip id" do
      origin_predictions = [%Prediction{time: @time, trip: @trip0}, %Prediction{time: @time, trip: @trip1}]
      destination_predictions = [%Prediction{time: @time, trip: @trip0}, %Prediction{time: @time, trip: @trip1}]
      grouped_trips = group_trips([@schedule_pair0, @schedule_pair1], origin_predictions, destination_predictions)

      assert Enum.count(grouped_trips) == 2
      for {scheduled, _, departure_prediction, arrival_prediction} <- grouped_trips do
        assert scheduled.trip.id == departure_prediction.trip.id
        assert scheduled.trip.id == arrival_prediction.trip.id
      end
    end
    test "Predictions are shown first" do
      origin_predictions = [%Prediction{time: @time, trip: @trip1}]
      destination_predictions = [%Prediction{time: @time, trip: @trip2}]
      grouped_trips = group_trips([@schedule_pair0, @schedule_pair1, @schedule_pair2], origin_predictions, destination_predictions)
      prediction? = fn ({_,_,nil, nil}) -> false
                      ({_,_, _, _}) -> true
                    end

      predictions = Enum.take_while(grouped_trips, &(prediction?.(&1)))
      assert Enum.count(predictions) == 2
    end
    test "with no predictions, returns all scheduled" do
      grouped_trips = group_trips([@schedule_pair1, @schedule_pair2], [], [])
      assert Enum.count(grouped_trips) == 2
      for {_scheduled, _destination, departure_prediction, arrival_prediction} <- grouped_trips do
        assert is_nil(departure_prediction)
        assert is_nil(arrival_prediction)
      end
    end
  end
end
