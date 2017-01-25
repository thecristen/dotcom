defmodule StopTimeTest do
  use ExUnit.Case, async: true
  import StopTimeList

  alias Schedules.{Schedule, Trip, Stop}
  alias Predictions.Prediction
  alias Routes.Route

  @route %Route{id: "86", type: 3, name: "86"}
  @origin_schedules [
    %Schedule{
      time: ~N[2017-01-01T09:00:00],
      route: @route,
      stop: %Stop{id: "1"},
      trip: %Trip{id: "t3"}
    },
    %Schedule{
      time: ~N[2017-01-01T07:00:00],
      route: @route,
      stop: %Stop{id: "1"},
      trip: %Trip{id: "t1"}
    },
    %Schedule{
      time: ~N[2017-01-01T08:00:00],
      route: @route,
      stop: %Stop{id: "1"},
      trip: %Trip{id: "t2"}
    },
    %Schedule{
      time: ~N[2017-01-01T08:15:00],
      route: @route,
      stop: %Stop{id: "2"},
      trip: %Trip{id: "t2"}
    }
  ]
  @od_schedules [
    {
      %Schedule{
        time: ~N[2017-01-01T08:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t2"}
      },
      %Schedule{
        time: ~N[2017-01-01T08:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t2"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T07:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t1"}
      },
      %Schedule{
        time: ~N[2017-01-01T07:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t1"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T09:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t3"}
      },
      %Schedule{
        time: ~N[2017-01-01T09:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t3"}
      }
    }
  ]
  @predictions [
    %Prediction{
      time: ~N[2017-01-01T08:05:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:16:00],
      route_id: @route.id,
      stop_id: "2",
      trip: %Trip{id: "t2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:32:00],
      route_id: @route.id,
      stop_id: "3",
      trip: %Trip{id: "t2"}
    }
  ]

  describe "build/1 with no origin or destination" do
    test "returns no times" do
      assert build(@origin_schedules, @predictions, nil, nil, true) == %StopTimeList{times: [], showing_all?: true}
    end
  end

  describe "build/1 with only origin" do
    test "returns StopTimes at that origin sorted by time with predictions first" do
      result = build(@origin_schedules, @predictions, "1", nil, false)

      assert result == %StopTimeList{
        times: [
          %StopTimeList.StopTime{
            arrival: nil,
            departure: {
              %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t2"}
              },
              %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route_id: @route.id,
                stop_id: "1",
                trip: %Trip{id: "t2"}
              }
            },
            trip: %Trip{id: "t2"}
          },
          %StopTimeList.StopTime{
            arrival: nil,
            departure: {
              %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t3"}
              },
              nil
            },
            trip: %Trip{id: "t3"}
          }
        ],
        showing_all?: false
      }
    end

    test "includes predictions without scheduled departures" do
      prediction = %Prediction{
        time: ~N[2017-01-01T07:05:00],
        route_id: @route.id,
        stop_id: "1",
        trip: %Trip{id: "t1"}
      }
      result = build(Enum.filter(@origin_schedules, & &1.trip.id != "t1"), [prediction | @predictions], "1", nil, false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        arrival: nil,
        departure: {
          nil,
          prediction
        },
        trip: %Trip{id: "t1"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@origin_schedules, @predictions, "1", nil, true)
      assert List.first(result.times) == %StopTimeList.StopTime{
        trip: %Trip{id: "t1"},
        departure: {
          %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "1"},
            trip: %Trip{id: "t1"}
          },
          nil
        }}
    end
  end

  describe "build/1 with origin and destination" do
    test "with origin and destination provided, returns StopTimes with arrivals and departures" do
      result = build(@od_schedules, @predictions, "1", "3", false)

      assert result == %StopTimeList{
        times: [
          %StopTimeList.StopTime{
            arrival: {
              %Schedule{
                time: ~N[2017-01-01T08:30:00],
                route: @route,
                stop: %Stop{id: "3"},
                trip: %Trip{id: "t2"}
              },
              %Prediction{
                time: ~N[2017-01-01T08:32:00],
                route_id: @route.id,
                stop_id: "3",
                trip: %Trip{id: "t2"}
              }
            },
            departure: {
              %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t2"}
              },
              %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route_id: @route.id,
                stop_id: "1",
                trip: %Trip{id: "t2"}
              }
            },
            trip: %Trip{id: "t2"}},
          %StopTimeList.StopTime{
            arrival: {
              %Schedule{
                time: ~N[2017-01-01T09:30:00],
                route: @route,
                stop: %Stop{id: "3"},
                trip: %Trip{id: "t3"}
              },
              nil
            },
            departure: {
              %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t3"}
              },
              nil
            },
            trip: %Trip{id: "t3"}
          }
        ],
        showing_all?: false
      }
    end

    test "includes predictions without scheduled departures" do
      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route_id: @route.id,
        stop_id: "3",
        trip: %Trip{id: "t_new"}
      }
      result = build(@od_schedules, [prediction | @predictions], "1", "3", false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        arrival: {nil, prediction},
        departure: {nil, nil},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "includes arrival predictions without corresponding departure predictions" do
      schedule_pair = {
        %Schedule{
          time: ~N[2017-01-01T07:00:00],
          route: @route,
          stop: %Stop{id: "1"},
          trip: %Trip{id: "t_new"}
        },
        %Schedule{
          time: ~N[2017-01-01T07:30:00],
          route: @route,
          stop: %Stop{id: "3"},
          trip: %Trip{id: "t_new"}
        }
      }
      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route_id: @route.id,
        stop_id: "3",
        trip: %Trip{id: "t_new"}
      }
      result = build([schedule_pair | @od_schedules], [prediction | @predictions], "1", "3", false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        departure: {elem(schedule_pair, 0), nil},
        arrival: {elem(schedule_pair, 1), prediction},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@od_schedules, @predictions, "1", "3", true)
      assert List.first(result.times) == %StopTimeList.StopTime{
        trip: %Trip{id: "t1"},
        departure: {
          %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "1"},
            trip: %Trip{id: "t1"}
          },
          nil
        },
        arrival: {
          %Schedule{
            time: ~N[2017-01-01T07:30:00],
            route: @route,
            stop: %Stop{id: "3"},
            trip: %Trip{id: "t1"}
          },
          nil
        }}
    end
  end
end
