defmodule Site.ScheduleV2Controller.OffsetTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.Offset

  describe "init/1" do
    test "takes no options" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    test "if an offset parameter is given, uses it" do
      conn = :get
      |> build_conn("/", offset: "12")
      |> call([])

      assert conn.assigns.offset == 12
    end

    test "when time is before the first trip offset is 0" do
      now = Util.now

      conn = now
      |> make_timetable_schedules
      |> assign(:date_time, Timex.shift(now, minutes: -1))
      |> call([])

      assert conn.assigns.offset == 0
    end

    test "when time is during the first trip offset is 0" do
      now = Util.now

      conn = now
      |> make_timetable_schedules
      |> assign(:date_time, Timex.shift(now, minutes: 5))
      |> call([])

      assert conn.assigns.offset == 0
    end

    test "when time is right after the first trip offset is 1" do
      now = Util.now

      conn = now
      |> make_timetable_schedules
      |> assign(:date_time, Timex.shift(now, minutes: 21))
      |> call([])

      assert conn.assigns.offset == 1
    end

    test "when time is during the second trip offset is 1" do
      now = Util.now

      conn = now
      |> make_timetable_schedules
      |> assign(:date_time, Timex.shift(now, hours: 1, minutes: 5))
      |> call([])

      assert conn.assigns.offset == 1
    end

    test "when time is after the third trip offset is 0" do
      now = Util.now

      conn = now
      |> make_timetable_schedules
      |> assign(:date_time, Timex.shift(now, hours: 4))
      |> call([])

      assert conn.assigns.offset == 0
    end
  end

  defp make_timetable_schedules(now) do
    conn = build_conn()
    |> assign(:date_time, now)
    |> assign(:timetable_schedules, Enum.flat_map(0..2, &make_one_trip(&1, now)))
  end

  defp make_one_trip(i, now) do
    Enum.map(0..2, 
      &make_schedule(
        Timex.shift(now, minutes: &1*10, hours: i), 
        "trip" <> Integer.to_string(i), 
        "stop" <> Integer.to_string(&1)))
  end

  defp make_schedule(time, trip_id, stop_id) do
    %{time: time,
      trip: %{id: trip_id},
      stop: %{id: stop_id}}
  end
end
