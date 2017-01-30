defmodule Site.ScheduleV2Controller.TripInfoTest do
  use Site.ConnCase, async: true
  import Site.ScheduleV2Controller.TripInfo
  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction

  @schedules [
    %Schedule{
      trip: %Trip{id: "past_trip"},
      stop: %Schedules.Stop{},
      time: Timex.shift(Util.now, hours: -1)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Schedules.Stop{},
      time: Timex.shift(Util.now, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "far_future_trip"},
      stop: %Schedules.Stop{},
      time: Timex.shift(Util.now, hours: 1)
    }
  ]
  @trip_schedules [
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Schedules.Stop{id: "first"},
      time: Timex.shift(Util.now, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Schedules.Stop{id: "last"},
      time: Timex.shift(Util.now, minutes: 4)
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
    |> assign(:date_time, Util.now)
    |> call(init)
  end

  defp schedules_to_predicted_schedules(schedules) do
    Enum.map(schedules, & %PredictedSchedule{schedule: &1})
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
    conn = conn_builder(conn, @schedules, trip: "long_trip", origin: "after_first", destination: "new_last")
    predicted_schedules = schedules_to_predicted_schedules(trip_fn("long_trip"))
    assert conn.assigns.trip_info == TripInfo.from_list(predicted_schedules, origin_id: "after_first", destination_id: "new_last", collapse?: true, vehicle: nil)
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
    conn =  conn
    |> assign(:date, Timex.shift(Util.service_date(), days: 2))
    |> conn_builder([], trip: "long_trip")
    for %PredictedSchedule{schedule: _schedule, prediction: prediction} <- List.flatten(conn.assigns.trip_info.sections) do
      refute prediction
    end
  end

  test "Trip predictions are fetched if date is service day", %{conn: conn} do
    conn = conn
    |> assign(:date, Util.service_date())
    |> conn_builder([], trip: "long_trip")
    predicted_schedules = List.flatten(conn.assigns.trip_info.sections)
    assert Enum.find(predicted_schedules, &match?(%PredictedSchedule{prediction: %Prediction{}}, &1))
  end
end
