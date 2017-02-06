defmodule Site.ScheduleV2Controller.TripInfoTest do
  use Site.ConnCase, async: true
  import Site.ScheduleV2Controller.TripInfo
  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction

  @time Util.now()

  @schedules [
    %Schedule{
      trip: %Trip{id: "past_trip"},
      stop: %Schedules.Stop{},
      time: Timex.shift(@time, hours: -1)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Schedules.Stop{},
      time: Timex.shift(@time, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "far_future_trip"},
      stop: %Schedules.Stop{},
      time: Timex.shift(@time, hours: 1)
    }
  ]
  @trip_schedules [
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Schedules.Stop{id: "first"},
      time: Timex.shift(@time, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Schedules.Stop{id: "last"},
      time: Timex.shift(@time, minutes: 4)
    }
  ]

  @predictions [
    %Prediction{
      trip: %Trip{id: "32893585"},
      stop_id: "first"
    },
    %Prediction{
      trip: %Trip{id: "32893585"},
      stop_id: "last"
    }
  ]

  defp prediction_fn(_) do
    @predictions
  end

  defp trip_fn("32893585") do
    @trip_schedules
  end
  defp trip_fn("long_trip") do
    # add some extra schedule data so that we can collapse this trip
    @trip_schedules
    |> Enum.concat([
      %Schedule{
        stop: %Schedules.Stop{id: "after_first"},
        time: Timex.shift(List.last(@schedules).time, minutes: -4)
      },
      %Schedule{
        stop: %Schedules.Stop{id: "1"},
        time: Timex.shift(List.last(@schedules).time, minutes: -3)
      },
      %Schedule{
        stop: %Schedules.Stop{id: "2"},
        time: Timex.shift(List.last(@schedules).time, minutes: -2)
      },
      %Schedule{
        stop: %Schedules.Stop{id: "3"},
        time: Timex.shift(List.last(@schedules).time, minutes: -1)
      },
      %Schedule{
        stop: %Schedules.Stop{id: "new_last"},
        time: List.last(@schedules).time
      }
    ])
  end
  defp trip_fn("not_in_schedule") do
    []
  end

  defp vehicle_fn("32893585") do
    %Vehicles.Vehicle{}
  end
  defp vehicle_fn(_) do
    nil
  end

  defp conn_builder(conn, schedules, params \\ []) do
    init = init(trip_fn: &trip_fn/1, vehicle_fn: &vehicle_fn/1, prediction_fn: &prediction_fn/1)
    query_params = Map.new(params, fn {key,val} -> {Atom.to_string(key), val} end)
    params = put_in query_params["route"], "1"

    %{conn |
      request_path: schedule_v2_path(conn, :show, "1"),
      query_params: query_params,
      params: params}
    |> assign(:schedules, schedules)
    |> assign(:date_time, @time)
    |> assign(:date, Util.service_date())
    |> call(init)
  end

  test "does not assign a trip when schedules is empty", %{conn: conn} do
    conn = conn_builder(conn, [])
    assert conn.assigns.trip_info == nil
  end

  test "assigns trip_info when schedules is a list of schedules", %{conn: conn} do
    conn = conn_builder(conn, @schedules)
    predicted_schedules = PredictedSchedule.group_by_trip(@predictions, @trip_schedules)
    assert conn.assigns.trip_info == TripInfo.from_list(predicted_schedules, vehicle: %Vehicles.Vehicle{}, origin: "first", destination: "last")
  end

  test "assigns trip_info when schedules is a list of schedule tuples", %{conn: conn} do
    conn = conn_builder(conn, @schedules |> Enum.map(fn sched -> {sched, %Schedule{}} end))
    predicted_schedules = PredictedSchedule.group_by_trip(@predictions, @trip_schedules)
    assert conn.assigns.trip_info == TripInfo.from_list(predicted_schedules, vehicle: %Vehicles.Vehicle{}, origin: "first", destination: "last")
  end

  test "assigns trip_info when origin/destination are selected", %{conn: conn} do
    expected_stops = ["after_first", "1", "2", "3", "new_last"]
    conn = conn_builder(conn, [], trip: "long_trip", origin: "after_first", destination: "new_last")
    actual_stops = conn.assigns.trip_info.sections
    |> List.flatten
    |> Enum.map(& &1.schedule.stop.id)
    assert actual_stops == expected_stops
  end

  test "there's a separator if there are enough schedules", %{conn: conn} do
    conn = conn_builder(conn, [], trip: "long_trip")
    assert :separator in TripInfo.times_with_flags_and_separators(conn.assigns.trip_info)
  end

  test "no separator if show_collapsed_trip_stops? present in the URL", %{conn: conn} do
    conn = conn_builder(conn, [], trip: "long_trip", show_collapsed_trip_stops?: "")
    refute :separator in TripInfo.times_with_flags_and_separators(conn.assigns.trip_info)
  end

  test "does not assign a trip if there are no more trips left in the day", %{conn: conn} do
    conn = conn_builder(conn, [List.first(@schedules)])
    assert conn.assigns.trip_info == nil
  end

  test "redirects if we can't generate a trip info", %{conn: conn} do
    conn = conn_builder(
      conn, [],
      trip: "not_in_schedule",
      origin: "fake",
      destination: "fake",
      param: "param")
    expected_path = schedule_v2_path(conn, :show, "1", destination: "fake", origin: "fake", param: "param")
    assert conn.halted
    assert redirected_to(conn) == expected_path
  end

  test "Trip predictions are not fetched if date is not service day", %{conn: conn} do
    init = init(trip_fn: &trip_fn/1, vehicle_fn: &vehicle_fn/1, prediction_fn: &prediction_fn/1)
    conn = %{conn |
      request_path: schedule_v2_path(conn, :show, "1"),
      query_params: %{"trip" =>  "long_trip"}}
    |> assign(:schedules, [])
    |> assign(:date_time, @time)
    |> assign(:date, Timex.shift(Util.service_date(), days: 2))
    |> call(init)

    for %PredictedSchedule{schedule: _schedule, prediction: prediction} <- List.flatten(conn.assigns.trip_info.sections) do
      refute prediction
    end
  end

  test "Trip predictions are fetched if date is service day", %{conn: conn} do
    conn = conn
    |> conn_builder([], trip: "long_trip")
    predicted_schedules = List.flatten(conn.assigns.trip_info.sections)
    assert Enum.find(predicted_schedules, &match?(%PredictedSchedule{prediction: %Prediction{}}, &1))
  end

  test "does not assign trips for the subway if the date is in the future", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 25),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, minutes: 26),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 27),
        route: %Routes.Route{type: 1}
      }
    ]
    day = Timex.shift(Util.now, days: 1)
    init = init(trip_fn: &trip_fn/1, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_v2_path(conn, :show, "Red"),
      query_params: nil
    }
    |> assign(:schedules, schedules)
    |> assign(:date, day)
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    assert conn.assigns.trip_info == nil
  end

  test "does assign trips for the subway if the date is today and predictions are given", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 25),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, minutes: 26),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 27),
        route: %Routes.Route{type: 1}
      }
    ]
    day = Util.today()
    init = init(trip_fn: &trip_fn/1, vehicle_fn: &vehicle_fn/1, prediction_fn: &prediction_fn/1)

    conn = %{conn |
      request_path: schedule_v2_path(conn, :show, "Red"),
      query_params: nil
    }
    |> assign(:schedules, schedules)
    |> assign(:date, day)
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    assert conn.assigns.trip_info != nil
  end

  test "does not assign trip info for the subway if predictions not are given", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 25),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, minutes: 26),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 27),
        route: %Routes.Route{type: 1}
      }
    ]
    day = Util.today()
    init = init(trip_fn: &trip_fn/1, vehicle_fn: &vehicle_fn/1, prediction_fn: fn(_) -> [] end)

    conn = %{conn |
      request_path: schedule_v2_path(conn, :show, "Red"),
      query_params: nil
    }
    |> assign(:schedules, schedules)
    |> assign(:date, day)
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    refute conn.assigns.trip_info
  end

  test "does assign trips for the bus if the date is in the future", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 25),
        route: %Routes.Route{type: 3}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 26),
        route: %Routes.Route{type: 3}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Schedules.Stop{},
        time: Timex.shift(Util.now, hours: 27),
        route: %Routes.Route{type: 3}
      }
    ]
    day = Timex.shift(Util.now, days: 1)
    init = init(trip_fn: &trip_fn/1, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_v2_path(conn, :show, "1"),
      query_params: nil
    }
    |> assign(:schedules, schedules)
    |> assign(:date, day)
    |> assign(:route, %Routes.Route{type: 3})
    |> call(init)

    assert conn.assigns.trip_info != nil
  end

  describe "show_trips/2" do
    test "it is false when looking at a future date for subway" do
      day = Timex.shift(Util.now, days: 1)
      assert Site.ScheduleV2Controller.TripInfo.show_trips(day, 1) == false
    end

    test "is true when looking at the subway today" do
      day = Util.today
      assert Site.ScheduleV2Controller.TripInfo.show_trips(day, 1) == true
    end

    test "has the same behavior for light rail as for subway" do
      day = Util.today
      assert Site.ScheduleV2Controller.TripInfo.show_trips(day, 0) == true
      day = Timex.shift(Util.now, days: 1)
      assert Site.ScheduleV2Controller.TripInfo.show_trips(day, 0) == false
    end

    test "is true when looking at any non-subway route" do
      day = Timex.shift(Util.now, days: 1)
      assert Site.ScheduleV2Controller.TripInfo.show_trips(day, 3) == true
    end
  end
end
