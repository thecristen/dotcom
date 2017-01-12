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

    test "without an offset explicitly provided, uses the index of the next departing schedule" do
      now = Util.now

      conn = build_conn()
      |> assign(:date_time, now)
      |> assign(:all_schedules, Enum.map(-2..2, & %{time: Timex.shift(now, minutes: &1)}))
      |> call([])

      assert conn.assigns.offset == 3
    end

    test "if no schedules occur after now, uses 0 as the offset" do
      now = Util.now

      conn = build_conn()
      |> assign(:date_time, now)
      |> assign(:all_schedules, Enum.map(-5..-1, & %{time: Timex.shift(now, minutes: &1)}))
      |> call([])

      assert conn.assigns.offset == 0
    end
  end
end
