defmodule Site.ScheduleV2.TripInfoTest do
  use Site.ConnCase, async: true
  import Site.ScheduleV2.TripInfo
  alias Schedules.{Schedule, Trip, Stop}

  @all_schedules [
    %Schedule{
      trip: %Trip{id: "past_trip"},
      stop: %Stop{},
      time: Timex.shift(Util.now, hours: -1)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Stop{},
      time: Timex.shift(Util.now, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "far_future_trip"},
      stop: %Stop{},
      time: Timex.shift(Util.now, hours: 1)
    }
  ]
  @trip_schedules [
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Stop{id: "first"},
      time: Timex.shift(Util.now, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Stop{id: "last"},
      time: Timex.shift(Util.now, minutes: 4)
    }
  ]

  defp trip_fn("32893585") do
    @trip_schedules
  end
  defp trip_fn("long_trip") do
    # add some extra schedule data so that we can collapse this trip
    @trip_schedules
    |> Enum.concat([
      %Schedule{
        stop: %Stop{id: "after_first"}
      },
      %Schedule{
        stop: %Stop{}
      },
      %Schedule{
        stop: %Stop{}
      },
      %Schedule{
        stop: %Stop{id: "new_last"},
        time: List.last(@all_schedules).time
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

  defp conn_builder(conn, all_schedules, params \\ []) do
    init = init(trip_fn: &trip_fn/1, vehicle_fn: &vehicle_fn/1)
    query_params = Map.new(params, fn {key,val} -> {Atom.to_string(key), val} end)
    params = put_in query_params["route"], "1"

    %{conn |
      request_path: schedule_v2_path(conn, :show, "1"),
      query_params: query_params,
      params: params}
    |> assign(:all_schedules, all_schedules)
    |> assign(:date_time, Util.now)
    |> call(init)
  end

  test "does not assign a trip when all_schedules is empty", %{conn: conn} do
    conn = conn_builder(conn, [])
    assert conn.assigns.trip_info == nil
  end

  test "assigns trip_info when all_schedules is a list of schedules", %{conn: conn} do
    conn = conn_builder(conn, @all_schedules)
    assert conn.assigns.trip_info == TripInfo.from_list(@trip_schedules, vehicle: %Vehicles.Vehicle{}, origin: "first", destination: "last")
  end

  test "assigns trip_info when all_schedules is a list of schedule tuples", %{conn: conn} do
    conn = conn_builder(conn, @all_schedules |> Enum.map(fn sched -> {sched, %Schedule{}} end))
    assert conn.assigns.trip_info == TripInfo.from_list(@trip_schedules, vehicle: %Vehicles.Vehicle{}, origin: "first", destination: "last")
  end

  test "assigns trip_info when origin/destination are selected", %{conn: conn} do
    conn = conn_builder(conn, @all_schedules, trip: "long_trip", origin: "after_first", last: "new_last")
    assert conn.assigns.trip_info == TripInfo.from_list(trip_fn("long_trip"), origin_id: "after_first", destination_id: "new_last")
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
    conn = conn_builder(conn, [List.first(@all_schedules)])
    assert conn.assigns.trip_info == nil
  end

  test "redirects if we can't generate a trip info", %{conn: conn} do
    conn = conn_builder(
      conn, [],
      trip: "not_in_schedule",
      origin: "fake",
      destination: "fake",
      param: "param")
    expected_path = schedule_v2_path(conn, :show, "1", param: "param")
    assert redirected_to(conn) == expected_path
  end
end
