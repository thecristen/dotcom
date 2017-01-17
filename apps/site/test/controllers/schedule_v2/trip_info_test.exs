defmodule Site.ScheduleV2.TripInfoTest do
  use Site.ConnCase, async: true
  alias Routes.Route
  alias Site.ScheduleV2.TripInfo
  alias Schedules.{Stop, Schedule, Trip}

  @route %Route{id: "1", name: "1", key_route?: true, type: 3}

  @origin %Stop{id: "64", name: "Dudley Station"}
  @destination  %Stop{id: "110", name: "Massachusetts Ave @ Holyoke St"}
  @all_schedules [
    %Schedule{
      trip: %Trip{id: "past_trip"},
      time: Timex.shift(Util.now, hours: -1)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      time: Timex.shift(Util.now, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "far_future_trip"},
      time: Timex.shift(Util.now, hours: 1)
    }
  ]



  def conn_builder(conn, params) do
    init = TripInfo.init([])
    {all_schedules, params} = Keyword.pop(params, :all_schedules, [])
    conn = %{conn | params: Map.new(params, fn {key,val} -> {Atom.to_string(key), val} end)}
    conn
    |> assign(:all_schedules, all_schedules)
    |> TripInfo.call(init)
  end

  test "does not assign a trip when all_schedules is empty", %{conn: conn} do
    conn = conn_builder(conn, [])
    assert conn.assigns.trip == nil
    assert conn.assigns.trip_schedule == []
  end

  test "assigns a trip and trip_schedule when all_schedules is a list of schedules", %{conn: conn} do
    conn = conn_builder(conn, all_schedules: @all_schedules)
    assert conn.assigns.trip == "32893585"
    assert conn.assigns.trip_schedule |> List.first |> Map.get(:stop) == @origin
    assert conn.assigns.trip_schedule |> List.last |> Map.get(:stop) == @destination
  end

  test "assigns a trip and trip_schedule when all_schedules is a list of schedule tuples", %{conn: conn} do
    conn = conn_builder(conn, all_schedules: @all_schedules |> Enum.map(fn sched -> {sched, %Schedule{}} end))
    assert conn.assigns.trip == "32893585"
    assert conn.assigns.trip_schedule |> List.first |> Map.get(:stop) == @origin
    assert conn.assigns.trip_schedule |> List.last |> Map.get(:stop) == @destination
  end

  test "does not assign a trip if there are no more trips left in the day", %{conn: conn} do
    conn = conn_builder(conn, all_schedules: [List.first(@all_schedules)])
    assert conn.assigns.trip == nil
    assert conn.assigns.trip_schedule == []
  end
end
