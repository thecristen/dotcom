defmodule StopTimeTest do
  use ExUnit.Case, async: true
  import StopTimeList

  alias Schedules.{Schedule, Trip, Stop}
  alias Predictions.Prediction
  alias Routes.Route
  alias StopTimeList.StopTime

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 | 7:00  |       |
  # stop2 | 8:00  | 8:15  |
  # stop3 | 9:00  |       |
   
  @route %Route{id: "86", type: 3, name: "86"}
  @origin_schedules [
    %Schedule{
      time: ~N[2017-01-01T09:00:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip3"}
    },
    %Schedule{
      time: ~N[2017-01-01T07:00:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip1"}
    },
    %Schedule{
      time: ~N[2017-01-01T08:00:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip2"}
    },
    %Schedule{
      time: ~N[2017-01-01T08:15:00],
      route: @route,
      stop: %Stop{id: "stop2"},
      trip: %Trip{id: "trip2"}
    }
  ]

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 | 7:00  | 8:00  | 9:00
  # stop2 |       |       |
  # stop3 | 7:30  | 8:30  | 9:30

  @od_schedules [
    {
      %Schedule{
        time: ~N[2017-01-01T08:00:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip2"}
      },
      %Schedule{
        time: ~N[2017-01-01T08:30:00],
        route: @route,
        stop: %Stop{id: "stop3"},
        trip: %Trip{id: "trip2"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T07:00:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip1"}
      },
      %Schedule{
        time: ~N[2017-01-01T07:30:00],
        route: @route,
        stop: %Stop{id: "stop3"},
        trip: %Trip{id: "trip1"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T09:00:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip3"}
      },
      %Schedule{
        time: ~N[2017-01-01T09:30:00],
        route: @route,
        stop: %Stop{id: "stop3"},
        trip: %Trip{id: "trip3"}
      }
    }
  ]

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 |       | 8:05  |     
  # stop2 |       | 8:16  |
  # stop3 |       | 8:32  |     

  @predictions [
    %Prediction{
      time: ~N[2017-01-01T08:05:00],
      route_id: @route.id,
      stop_id: "stop1",
      trip: %Trip{id: "trip2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:16:00],
      route_id: @route.id,
      stop_id: "stop2",
      trip: %Trip{id: "trip2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:32:00],
      route_id: @route.id,
      stop_id: "stop3",
      trip: %Trip{id: "trip2"}
    }
  ]

  # -----------------------------------------------------
  #         trip1 | trip2 | trip3 | trip4 | trip5 | trip6
  # -----------------------------------------------------
  # stop1 | 8:05  | 8:16  | 8:32  | 8:35  | 8:36  | 8:37
  # stop2 |       |       |       |       |       |
  # stop3 |       |       |       |       |       | 8:38

  @origin_destination_predictions [
    %Prediction{
      time: ~N[2017-01-01T08:05:00],
      route_id: @route.id,
      stop_id: "stop1",
      trip: %Trip{id: "trip1"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:16:00],
      route_id: @route.id,
      stop_id: "stop1",
      trip: %Trip{id: "trip2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:32:00],
      route_id: @route.id,
      stop_id: "stop1",
      trip: %Trip{id: "trip3"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:35:00],
      route_id: @route.id,
      stop_id: "stop1",
      trip: %Trip{id: "trip4"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:36:00],
      route_id: @route.id,
      stop_id: "stop1",
      trip: %Trip{id: "trip5"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:37:00],
      route_id: @route.id,
      stop_id: "stop1",
      trip: %Trip{id: "trip6"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:38:00],
      route_id: @route.id,
      stop_id: "stop3",
      trip: %Trip{id: "trip6"}
    }
  ]

  describe "build/1 with no origin or destination" do
    test "returns no times" do
      assert build(@origin_schedules, @predictions, nil, nil, true) == %StopTimeList{times: [], showing_all?: true}
    end
  end

  describe "build/1 with only origin" do
    test "returns StopTimes at that origin sorted by time with predictions first" do
      result = build(@origin_schedules, @predictions, "stop1", nil, false)

      assert result == %StopTimeList{
        times: [
          %StopTimeList.StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route_id: @route.id,
                stop_id: "stop1",
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTimeList.StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip3"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip3"}
          }
        ],
        showing_all?: false
      }
    end

    test "includes predictions without scheduled departures" do
      prediction = %Prediction{
        time: ~N[2017-01-01T07:05:00],
        route_id: @route.id,
        stop_id: "stop1",
        trip: %Trip{id: "trip1"}
      }
      result = build(Enum.filter(@origin_schedules, & &1.trip.id != "trip1"), [prediction | @predictions], "stop1", nil, false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        arrival: nil,
        departure: %PredictedSchedule{
          schedule: nil,
          prediction: prediction
        },
        trip: %Trip{id: "trip1"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@origin_schedules, @predictions, "stop1", nil, true)
      assert List.first(result.times) == %StopTimeList.StopTime{
        trip: %Trip{id: "trip1"},
        departure: %PredictedSchedule{
          schedule: %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "stop1"},
            trip: %Trip{id: "trip1"}
          },
          prediction: nil
        }}
    end

    test "removes all scheduled time before the last prediction" do
      prediction = %Prediction{
        time: ~N[2017-01-01T09:05:00],
        route_id: @route.id,
        stop_id: "stop1",
        trip: %Trip{id: "trip4"}
      }
      schedule = %Schedule{
        time: ~N[2017-01-01T10:00:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip5"}
      }

      result = build([schedule | @origin_schedules], [prediction | @predictions], "stop1", nil, false)
      assert result == %StopTimeList{
        times: [
          %StopTimeList.StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route_id: @route.id,
                stop_id: "stop1",
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTimeList.StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: nil,
              prediction: %Prediction{
                time: ~N[2017-01-01T09:05:00],
                route_id: @route.id,
                stop_id: "stop1",
                trip: %Trip{id: "trip4"}
              }
            },
            trip: %Trip{id: "trip4"}
          },
          %StopTimeList.StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T10:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip5"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip5"}
          },
        ],
        showing_all?: false
      }
    end
  end

  describe "build/1 with origin and destination" do
    test "with origin and destination provided, returns StopTimes with arrivals and departures" do
      result = build(@od_schedules, @predictions, "stop1", "stop3", false)

      assert result == %StopTimeList{
        times: [
          %StopTimeList.StopTime{
            arrival: %PredictedSchedule{
              schedule: %Schedule{ 
                time: ~N[2017-01-01T08:30:00],
                route: @route,
                stop: %Stop{id: "stop3"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:32:00],
                route_id: @route.id,
                stop_id: "stop3",
                trip: %Trip{id: "trip2"}
              }
            },
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route_id: @route.id,
                stop_id: "stop1",
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}},
          %StopTimeList.StopTime{
            arrival: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:30:00],
                route: @route,
                stop: %Stop{id: "stop3"},
                trip: %Trip{id: "trip3"}
              },
              prediction: nil
            },
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip3"}
              },
            prediction: nil
            },
            trip: %Trip{id: "trip3"}
          }
        ],
        showing_all?: false
      }
    end

    test "includes predictions without scheduled departures" do
      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route_id: @route.id,
        stop_id: "stop3",
        trip: %Trip{id: "t_new"}
      }
      result = build(@od_schedules, [prediction | @predictions], "stop1", "stop3", false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        arrival: %PredictedSchedule{schedule: nil, prediction: prediction},
        departure: %PredictedSchedule{schedule: nil, prediction: nil},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "includes arrival predictions without corresponding departure predictions" do
      schedule_pair = {
        %Schedule{
          time: ~N[2017-01-01T07:00:00],
          route: @route,
          stop: %Stop{id: "stop1"},
          trip: %Trip{id: "t_new"}
        },
        %Schedule{
          time: ~N[2017-01-01T07:30:00],
          route: @route,
          stop: %Stop{id: "stop3"},
          trip: %Trip{id: "t_new"}
        }
      }
      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route_id: @route.id,
        stop_id: "stop3",
        trip: %Trip{id: "t_new"}
      }
      result = build([schedule_pair | @od_schedules], [prediction | @predictions], "stop1", "stop3", false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        departure: %PredictedSchedule{schedule: elem(schedule_pair, 0), prediction: nil},
        arrival: %PredictedSchedule{schedule: elem(schedule_pair, 1), prediction: prediction},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@od_schedules, @predictions, "stop1", "stop3", true)
      assert List.first(result.times) == %StopTimeList.StopTime{
        trip: %Trip{id: "trip1"},
        departure: %PredictedSchedule{
          schedule: %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "stop1"},
            trip: %Trip{id: "trip1"}
          },
          prediction: nil
        },
        arrival: %PredictedSchedule{
          schedule: %Schedule{
            time: ~N[2017-01-01T07:30:00],
            route: @route,
            stop: %Stop{id: "stop3"},
            trip: %Trip{id: "trip1"}
          },
          prediction: nil
        }}
    end
  end

  describe "build_predictions_only/3" do
    test "Results contain no schedules for origin" do
      result = build_predictions_only(@origin_destination_predictions, "stop1", nil).times
      assert length(result) == 5
      for stop_time <- result do
        assert %StopTimeList.StopTime{departure: %PredictedSchedule{schedule: nil}, arrival: nil} = stop_time
      end
    end

    test "Results contain no schedules for origin and destination" do
      result = build_predictions_only(@origin_destination_predictions, "stop1", "stop3").times
      assert length(result) == 5
      for stop_time <- result do
        assert %StopTimeList.StopTime{departure: %PredictedSchedule{schedule: nil}, arrival: %PredictedSchedule{schedule: nil}} = stop_time
      end
    end

    test "All times have departure predictions" do
      result = build_predictions_only(@origin_destination_predictions, "stop1", "stop3").times
      assert length(result) == 5
      for stop_time <- result do
        assert stop_time.departure.prediction != nil
      end
    end

    test "handles predictions not associated with a trip" do
      prediction = %Prediction{
        time: Util.now,
        route_id: @route.id,
        stop_id: "stop1",
        trip: nil
      }
      result = build_predictions_only([prediction], "stop1", nil)
      assert result == %StopTimeList{
        showing_all?: true,
        times: [
          %StopTimeList.StopTime{
            trip: nil,
            departure: %PredictedSchedule{
              schedule: nil,
              prediction: prediction
            }}
        ]}
    end

    test "handles predictions not associated with a trip given an origin and destination" do
      prediction = %Prediction{
        time: Util.now,
        route_id: @route.id,
        stop_id: "stop1",
        trip: nil
      }
      arrival_prediction = %{prediction | stop_id: "stop3"}
      predictions = [prediction, arrival_prediction]
      result = build_predictions_only(predictions, "stop1", "stop3")
      assert result == %StopTimeList{
        showing_all?: true,
        times: [
          %StopTimeList.StopTime{
            trip: nil,
            departure: %PredictedSchedule{
              schedule: nil,
              prediction: prediction
            },
            arrival: %PredictedSchedule{
              schedule: nil,
              prediction: arrival_prediction}}
        ]}
    end
  end

  describe "StopTime.display_status/1" do
    test "returns the same as StopTime.display_status/2 with a nil second argument" do
      assert StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "On Time"}}) == StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "On Time"}}, nil)
    end
  end

  describe "StopTime.display_status/2" do
    test "uses the departure status if it exists" do
      result = StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "On Time"}}, nil)

      assert IO.iodata_to_binary(result) == "On Time"
    end

    test "includes track number if present" do
      result = StopTime.display_status(%PredictedSchedule{schedule: nil, prediction: %Prediction{status: "All Aboard", track: "5"}}, nil)

      assert IO.iodata_to_binary(result) == "All Aboard on track 5"
    end

    test "returns a readable message if there's a difference between the scheduled and predicted times" do
      now = Util.now
      result = StopTime.display_status(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 5)}}, %PredictedSchedule{schedule: nil, prediction: nil})

      assert IO.iodata_to_binary(result) == "Delayed 5 minutes"
    end

    test "returns the empty string if the predicted and scheduled times are the same" do
      now = Util.now
      result = StopTime.display_status(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: now}}, %PredictedSchedule{schedule: nil, prediction: nil})

      assert IO.iodata_to_binary(result) == ""
    end

    test "takes the max of the departure and arrival time delays" do
      departure = Util.now
      arrival = Timex.shift(departure, minutes: 30)
      result = StopTime.display_status(
        %PredictedSchedule{schedule: %Schedule{time: departure}, prediction: %Prediction{time: Timex.shift(departure, minutes: 5)}},
        %PredictedSchedule{schedule: %Schedule{time: arrival}, prediction: %Prediction{time: Timex.shift(arrival, minutes: 10)}}
      )

      assert IO.iodata_to_binary(result) == "Delayed 10 minutes"
    end

    test "handles nil arrivals" do
      now = Util.now
      result = StopTime.display_status(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 5)}}, nil)

      assert IO.iodata_to_binary(result) == "Delayed 5 minutes"
    end

    test "inflects the delay correctly" do
      now = Util.now
      result = StopTime.display_status(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 1)}}, nil)

      assert IO.iodata_to_binary(result) == "Delayed 1 minute"
    end
  end

  describe "StopTime.delay/1" do
    test "returns the difference between a schedule and prediction" do
      now = Util.now

      assert StopTime.delay(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: %Prediction{time: Timex.shift(now, minutes: 14)}}) == 14
    end

    test "returns 0 if either time is nil, or if the argument itself is nil" do
      now = Util.now
      assert StopTime.delay(%PredictedSchedule{schedule: nil, prediction: %Prediction{time: Timex.shift(now, minutes: 14)}}) == 0
      assert StopTime.delay(%PredictedSchedule{schedule: %Schedule{time: now}, prediction: nil}) == 0
      assert StopTime.delay(%PredictedSchedule{schedule: nil, prediction: nil}) == 0
      assert StopTime.delay(nil) == 0
    end
  end
end
