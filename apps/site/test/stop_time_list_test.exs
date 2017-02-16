defmodule StopTimeListTest do
  use ExUnit.Case, async: true
  import StopTimeList

  alias Schedules.{Schedule, Trip, Stop}
  alias Predictions.Prediction
  alias Routes.Route

  @time ~N[2017-01-01T22:30:00]
  @route %Route{id: "86", type: 3, name: "86"}

  @sched_stop1_trip1__7_00 %Schedule{
    time: ~N[2017-01-01T07:00:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip1"}
  }

  @sched_stop1_trip2__8_00 %Schedule{
    time: ~N[2017-01-01T08:00:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip2"}
  }

  @sched_stop1_trip3__9_00 %Schedule{
    time: ~N[2017-01-01T09:00:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip3"}
  }

  @sched_stop2_trip2__8_15 %Schedule{
    time: ~N[2017-01-01T08:15:00],
    route: @route,
    stop: %Stop{id: "stop2"},
    trip: %Trip{id: "trip2"}
  }

  @sched_stop3_trip1__7_30 %Schedule{
    time: ~N[2017-01-01T07:30:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip1"}
  }

  @sched_stop3_trip2__8_30 %Schedule{
    time: ~N[2017-01-01T08:30:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip2"}
  }

  @sched_stop3_trip3__9_30 %Schedule{
    time: ~N[2017-01-01T09:30:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip3"}
  }

  @pred_stop1_trip2__8_05 %Prediction{
    time: ~N[2017-01-01T08:05:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip2"}
  }

  @pred_stop2_trip2__8_16 %Prediction{
    time: ~N[2017-01-01T08:16:00],
    route: @route,
    stop: %Stop{id: "stop2"},
    trip: %Trip{id: "trip2"}
  }

  @pred_stop3_trip2__8_32 %Prediction{
    time: ~N[2017-01-01T08:32:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip2"}
  }

  @pred_stop1_trip1__8_05 %Prediction{
      time: ~N[2017-01-01T08:05:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip1"}
  }

  @pred_stop1_trip2__8_16 %Prediction{
      time: ~N[2017-01-01T08:16:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip2"}
  }

  @pred_stop1_trip3__8_32 %Prediction{
      time: ~N[2017-01-01T08:32:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip3"}
  }

  @pred_stop1_trip4__8_35 %Prediction{
      time: ~N[2017-01-01T08:35:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip4"}
  }

  @pred_stop1_trip5__8_36 %Prediction{
      time: ~N[2017-01-01T08:36:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip5"}
  }

  @pred_stop1_trip6__8_37 %Prediction{
      time: ~N[2017-01-01T08:37:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip6"}
  }

  @pred_stop3_trip6__8_38 %Prediction{
      time: ~N[2017-01-01T08:38:00],
      route: @route,
      stop: %Stop{id: "stop3"},
      trip: %Trip{id: "trip6"}
  }

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 | 7:00  | 8:00  | 9:00
  # stop2 |       | 8:15  |
  # stop3 |       |       |

  @origin_schedules [
      @sched_stop1_trip3__9_00,
      @sched_stop1_trip1__7_00,
      @sched_stop1_trip2__8_00,
      @sched_stop2_trip2__8_15,
  ]

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 | 7:00  | 8:00  | 9:00
  # stop2 |       |       |
  # stop3 | 7:30  | 8:30  | 9:30

  @od_schedules [
      { @sched_stop1_trip2__8_00, @sched_stop3_trip2__8_30 },
      { @sched_stop1_trip1__7_00, @sched_stop3_trip1__7_30 },
      { @sched_stop1_trip3__9_00, @sched_stop3_trip3__9_30 },
  ]

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 |       | 8:05  |
  # stop2 |       | 8:16  |
  # stop3 |       | 8:32  |

  @predictions [
    @pred_stop1_trip2__8_05,
    @pred_stop2_trip2__8_16,
    @pred_stop3_trip2__8_32,
  ]

  # -----------------------------------------------------
  #         trip1 | trip2 | trip3 | trip4 | trip5 | trip6
  # -----------------------------------------------------
  # stop1 | 8:05  | 8:16  | 8:32  | 8:35  | 8:36  | 8:37
  # stop2 |       |       |       |       |       |
  # stop3 |       |       |       |       |       | 8:38

  @origin_destination_predictions [
    @pred_stop1_trip1__8_05,
    @pred_stop1_trip2__8_16,
    @pred_stop1_trip3__8_32,
    @pred_stop1_trip4__8_35,
    @pred_stop1_trip5__8_36,
    @pred_stop1_trip6__8_37,
    @pred_stop3_trip6__8_38,
  ]

  describe "build/1 with no origin or destination" do
    test "returns no times" do
      assert build(@origin_schedules, @predictions, nil, nil, :keep_all, @time) == %StopTimeList{times: [], showing_all?: true}
    end
  end

  describe "build/1 with only origin" do
    test "returns StopTimes at that origin sorted by time with predictions first" do

      # --------------------------------------------
      #         trip1   | trip2           | trip3
      # --------------------------------------------
      # stop1 | 7:00(s) | 8:00(s) 8:05(p) | 9:00(s)
      # stop2 |         | 8:15(s) 8:16(p) |
      # stop3 |         | 8:32(p)         |


      result = build(@origin_schedules, @predictions, "stop1", nil, :predictions_then_schedules, @time)

      assert result == %StopTimeList{
        times: [
          %StopTime{
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
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
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
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip1"}
      }
      result = build(Enum.filter(@origin_schedules, & &1.trip.id != "trip1"), [prediction | @predictions], "stop1", nil, :predictions_then_schedules, @time)

      assert List.first(result.times) == %StopTime{
        arrival: nil,
        departure: %PredictedSchedule{
          schedule: nil,
          prediction: prediction
        },
        trip: %Trip{id: "trip1"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@origin_schedules, @predictions, "stop1", nil, :keep_all, @time)
      assert List.first(result.times) == %StopTime{
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
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip4"}
      }
      schedule = %Schedule{
        time: ~N[2017-01-01T10:00:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip5"}
      }

      result = build([schedule | @origin_schedules], [prediction | @predictions], "stop1", nil, :predictions_then_schedules, @time)
      assert result == %StopTimeList{
        times: [
          %StopTime{
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
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: nil,
              prediction: %Prediction{
                time: ~N[2017-01-01T09:05:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip4"}
              }
            },
            trip: %Trip{id: "trip4"}
          },
          %StopTime{
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

    test "only leaves upcoming trips and one previous" do

      # ------------------------------
      #         trip1 | trip2 | trip3
      # ------------------------------
      # stop1 | 7:00  | 8:00  | 9:00
      # stop2 |       | 8:15  |
      # stop3 |       |       |

      result = build(@origin_schedules, [], "stop1", nil, :last_trip_and_upcoming, ~N[2017-01-01T08:30:00])

      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
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
          },
        ],
        showing_all?: false
      }

    end

    test "returns all trips if they are upcoming" do

      # ------------------------------
      #         trip1 | trip2 | trip3
      # ------------------------------
      # stop1 | 7:00  | 8:00  | 9:00
      # stop2 |       | 8:15  |
      # stop3 |       |       |

      result = build(@origin_schedules, [], "stop1", nil, :last_trip_and_upcoming, ~N[2017-01-01T06:30:00])

      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T07:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip1"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip1"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
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
          },
        ],
        showing_all?: false
      }

    end
  end

  describe "build/1 with origin and destination" do

    test "with origin and destination provided, returns StopTimes with arrivals and departures" do

      # --------------------------------------------
      #         trip1   | trip2           | trip3
      # --------------------------------------------
      # stop1 | 7:00(s) | 8:00(s) 8:05(p) | 9:00(s)
      # stop2 |         | 8:16(p)         |
      # stop3 | 7:30(s) | 8:30(s) 8:32(p) | 9:30(s)

      result = build(@od_schedules, @predictions, "stop1", "stop3", :predictions_then_schedules, @time)

      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:30:00],
                route: @route,
                stop: %Stop{id: "stop3"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:32:00],
                route: @route,
                stop: %Stop{id: "stop3"},
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
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}},
          %StopTime{
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

    test "includes arrival predictions without corresponding departure predictions" do
      orig_sched = %Schedule{
          time: ~N[2017-01-01T06:10:00],
          route: @route,
          stop: %Stop{id: "stop1"},
          trip: %Trip{id: "t_new"}
        }

        dest_sched = %Schedule{
          time: ~N[2017-01-01T06:30:00],
          route: @route,
          stop: %Stop{id: "stop3"},
          trip: %Trip{id: "t_new"}
        }

      schedule_pair = {orig_sched, dest_sched}

      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route: @route,
        stop: %Stop{id: "stop3"},
        trip: %Trip{id: "t_new"}
      }

      # --------------------------------------------------
      #         trip1   | trip2           | trip3 | t_new
      # --------------------------------------------------
      # stop1 | 7:00(s) | 8:00(s) 8:05(p) | 9:00  | 6:10(s)
      # stop2 |         | 8:16(p)         |       |
      # stop3 | 7:30(s) | 8:30(s) 8:32(p) | 9:30  | 6:30(s) 7:31(p)

      result = build([schedule_pair | @od_schedules], [prediction | @predictions], "stop1", "stop3", :last_trip_and_upcoming, ~N[2017-01-01T06:15:00])
      stop_time = hd(result.times)

      assert stop_time == %StopTime{
        departure: %PredictedSchedule{schedule: orig_sched, prediction: nil},
        arrival: %PredictedSchedule{schedule: dest_sched, prediction: prediction},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@od_schedules, @predictions, "stop1", "stop3", :keep_all, @time)
      assert List.first(result.times) == %StopTime{
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
        assert %StopTime{departure: %PredictedSchedule{schedule: nil}, arrival: nil} = stop_time
      end
    end

    test "Results contain no schedules for origin and destination" do

      # -----------------------------------------------------
      #         trip1 | trip2 | trip3 | trip4 | trip5 | trip6
      # -----------------------------------------------------
      # stop1 | 8:05  | 8:16  | 8:32  | 8:35  | 8:36  | 8:37
      # stop2 |       |       |       |       |       |
      # stop3 |       |       |       |       |       | 8:38

      result = build_predictions_only(@origin_destination_predictions, "stop1", "stop3").times

      assert length(result) == 1

      stop_time = hd(result)
      assert stop_time.trip.id == "trip6"
      assert %StopTime{departure: %PredictedSchedule{schedule: nil}, arrival: %PredictedSchedule{schedule: nil}} = stop_time
    end

    test "All times have departure predictions" do

      # -----------------------------------------------------
      #         trip1 | trip2 | trip3 | trip4 | trip5 | trip6
      # -----------------------------------------------------
      # stop1 | 8:05  | 8:16  | 8:32  | 8:35  | 8:36  | 8:37
      # stop2 |       |       |       |       |       |
      # stop3 |       |       |       |       |       | 8:38

      result = build_predictions_only(@origin_destination_predictions, "stop1", "stop3").times
      assert length(result) == 1

      stop_time = hd(result)
      assert stop_time.trip.id == "trip6"
      assert stop_time.departure.prediction != nil
    end

    test "handles predictions not associated with a trip" do
      prediction = %Prediction{
        time: Util.now,
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: nil
      }
      result = build_predictions_only([prediction], "stop1", nil)
      assert result == %StopTimeList{
        showing_all?: true,
        times: [
          %StopTime{
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
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip1"}
      }
      arrival_prediction = %{prediction | stop: %Stop{id: "stop3"}}
      predictions = [prediction, arrival_prediction]
      result = build_predictions_only(predictions, "stop1", "stop3")
      assert result == %StopTimeList{
        showing_all?: true,
        times: [
          %StopTime{
            trip: nil,
            departure: %PredictedSchedule{
              schedule: nil,
              prediction: prediction
            },
            arrival: %PredictedSchedule{
              schedule: nil,
              prediction: arrival_prediction},
            trip: %Trip{id: "trip1"}}
        ]}
    end
  end
end
