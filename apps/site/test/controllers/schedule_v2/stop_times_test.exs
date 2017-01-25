defmodule Site.ScheduleV2Controller.StopTimesTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.StopTimes
  import Plug.Conn, only: [assign: 3, fetch_query_params: 1]

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
      |> fetch_query_params
      |> call([])

      assert conn.assigns.stop_times != nil
    end

    test "assigns stop_times for subway", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{type: 1})
      |> assign(:schedules, [])
      |> assign(:predictions, [])
      |> fetch_query_params
      |> call([])

      assert conn.assigns.stop_times != nil
    end
  end
end
