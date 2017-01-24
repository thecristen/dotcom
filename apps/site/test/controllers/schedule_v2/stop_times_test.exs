defmodule Site.ScheduleV2.StopTimesTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2.StopTimes
  import Plug.Conn, only: [assign: 3]

  describe "init/1" do
    test "takes no options" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    test "assigns stop_times", %{conn: conn} do
      conn = conn
      |> assign(:schedules, [])
      |> assign(:predictions, [])
      |> assign(:origin, nil)
      |> assign(:destination, nil)
      |> call([])

      assert conn.assigns.stop_times != nil
    end
  end
end
