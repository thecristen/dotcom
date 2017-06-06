defmodule Site.VehicleTooltipTest do
  use ExUnit.Case, async: true

  import VehicleTooltip
  import Site.ViewHelpers, only: [format_schedule_time: 1]

  @locations %{{"CR-Weekday-Spring-17-515", "place-sstat"} =>
                %Vehicles.Vehicle{latitude: 1.1, longitude: 2.2, status: :stopped, stop_id: "place-sstat",
                                  trip_id: "CR-Weekday-Spring-17-515"}}

  @predictions [%Predictions.Prediction{departing?: true, time: ~N[2017-01-01T11:00:00], status: "On Time",
                                        trip: %Schedules.Trip{id: "CR-Weekday-Spring-17-515"}}]

  @route %Routes.Route{type: 2}

  @tooltips build_map(@route, @locations, @predictions)

  @tooltip_base @tooltips["place-sstat"]

  describe "build_map/3" do
    test "verify the VehicleTooltip data" do
      assert length(Map.keys(@tooltips)) == 2
      assert Map.has_key?(@tooltips, {"CR-Weekday-Spring-17-515", "place-sstat"})
      assert Map.has_key?(@tooltips, "place-sstat")
      assert @tooltip_base.route.type == 2
      assert @tooltip_base.trip.name == "515"
      assert @tooltip_base.trip.headsign == "Worcester"
      assert @tooltip_base.prediction.status == "On Time"
      assert @tooltip_base.vehicle.status == :stopped
    end
  end

  describe "prediction_time_text/1" do
    test "when there is no prediction, there is no prediction time" do
      tooltip = %{@tooltip_base | prediction: nil}
      assert tooltip(@tooltip_base) =~ "11:00A"
      refute tooltip(tooltip) =~ "11:00A"
    end

    test "when a prediction has a time, gives the arrival time" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | departing?: false,
                                                                           time: ~N[2017-01-01T13:00:00]}}
      assert tooltip(tooltip) =~ "Expected arrival at 01:00P"
    end

    test "when a prediction is departing, gives the departing time" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | departing?: true,
                                                                           time: ~N[2017-01-01T12:00:00]}}
      assert tooltip(tooltip) =~ "Expected departure at 12:00P"
    end

    test "when a prediction does not have a time, gives nothing" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | time: nil}}
      result = tooltip(tooltip)
      refute result =~ "P"
      refute result =~ "A"
    end
  end

  describe "prediction_status_text/1" do
    test "when a prediction has a track, gives the time, the status and the track" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | status: "Now Boarding", track: "4"}}
      assert tooltip(tooltip) =~ "Now boarding on track 4"
    end

    test "when a prediction does not have a track, gives nothing" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | status: "Now Boarding", track: nil}}
      refute tooltip(tooltip) =~ "Now boarding"
    end
  end

  describe "build_prediction_tooltip/2" do
    test "when there is no time or status for the prediction, returns stop name" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | status: nil, time: nil}}
      assert tooltip(tooltip) =~ "South Station"
    end

    test "when there is a time but no status for the prediction, gives a tooltip with arrival time" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | status: nil, time: ~N[2017-01-01T12:00:00]}}
      assert tooltip(tooltip) =~ "12:00P"
    end

    test "when there is a status but no time for the prediction, gives a tooltip with the status" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | status: "Now Boarding", time: nil}}
      result = tooltip(tooltip)
      assert result =~ "has arrived"
      refute result =~ "A"
      refute result =~ "P"
    end

    test "when there is a status and a time for the prediction, gives a tooltip with both and also replaces double quotes with single quotes" do
      tooltip = %{@tooltip_base | prediction: %{@tooltip_base.prediction | status: "now boarding", time: ~N[2017-01-01T12:00:00]}}

      # there will be four single quotes, two for each class declaration
      assert length(String.split(tooltip(tooltip), "'")) == 5
    end
  end

  describe "prediction_tooltip/1" do
    test "creates a tooltip for the prediction" do
      time = ~N[2017-02-17T05:46:28]
      formatted_time = format_schedule_time(time)
      result = tooltip(%{@tooltip_base | prediction: %Predictions.Prediction{time: time, status: "Now Boarding", track: "4"}})
      assert result =~ "Now boarding on track 4"
      assert result =~ "Expected arrival at #{formatted_time}"
    end
  end

  test "Displays text based on vehicle status" do
    tooltip1 = %{@tooltip_base | vehicle: %Vehicles.Vehicle{status: :incoming}}
    tooltip2 = %{@tooltip_base | vehicle: %Vehicles.Vehicle{status: :stopped}}
    tooltip3 = %{@tooltip_base | vehicle: %Vehicles.Vehicle{status: :in_transit}}

    assert tooltip(tooltip1) =~ "Worcester train 515 is on the way to"
    assert tooltip(tooltip2) =~ "Worcester train 515 has arrived"
    assert tooltip(tooltip3) =~ "Worcester train 515 has left"
  end

  describe "prediction_for_stop/2" do
    test "do not crash if vehicle prediction does not contain a trip" do
      predictions = [%Predictions.Prediction{departing?: true, time: ~N[2017-01-01T11:00:00], status: "On Time"}]
      tooltips = build_map(@route, @locations, predictions)
      tooltip = tooltips["place-sstat"]
      assert tooltip(tooltip) =~ "train 515 has arrived"
    end
  end

end
