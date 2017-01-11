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
    @prediction_time Timex.shift(@schedule, hours: 1)

    test "Prediction is used if one is given" do
      display_time = display_scheduled_prediction({%Schedule{time: @schedule_time}, %Prediction{time: @prediction_time}})
      assert safe_to_string(display_time) =~ format_schedule_time(@prediction_time)
      assert safe_to_string(display_time) =~ "fa fa-rss"
    end

    test "Scheduled time is used if no prediction is available" do
      display_time = display_scheduled_prediction({%Schedule{time: @schedule_time}, nil})
      assert safe_to_string(display_time) =~ format_schedule_time(@schedule_time)
      refute safe_to_string(display_time) =~ "fa fa-rss"
    end
  end
end
