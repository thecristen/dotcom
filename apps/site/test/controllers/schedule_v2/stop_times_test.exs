defmodule Site.ScheduleV2Controller.StopTimesTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.StopTimes
  import Plug.Conn, only: [assign: 3, fetch_query_params: 1]

  alias Schedules.{Schedule, Trip, Stop}

  describe "init/1" do
    test "takes no options" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    defp setup_conn(conn, params, schedules, predictions, now) do
      %{conn | params: params}
      |> assign(:schedules, schedules)
      |> assign(:predictions, predictions)
      |> assign(:date_time, now)
      |> fetch_query_params
      |> call([])
    end

    test "assigns stop_times", %{conn: conn} do
      conn = setup_conn(conn, %{}, [], [], Util.now)

      assert conn.assigns.stop_times == %StopTimeList{times: [], showing_all?: false}
    end

    test "filters out schedules in the past by default, leaving the last entry before now", %{conn: conn} do
      now = Util.now
      stop = %Stop{id: "stop"}
      schedules = for hour <- [-3, -2, -1, 1, 2, 3] do
        %Schedule{
          time: Timex.shift(now, hours: hour),
          trip: %Trip{id: "trip-#{hour}"},
          stop: stop
        }
      end
      conn = setup_conn(conn, %{"origin" => stop.id}, schedules, [], now)

      assert conn.assigns.stop_times == StopTimeList.build(Enum.drop(schedules, 2), [], stop.id, nil, false)
    end

    test "if show_all_trips is true, doesn't filter schedules", %{conn: conn} do
      now = Util.now
      stop = %Stop{id: "stop"}
      schedules = for hour <- [-3, -2, -1, 1, 2, 3] do
        %Schedule{
          time: Timex.shift(now, hours: hour),
          trip: %Trip{id: "trip-#{hour}"},
          stop: stop
        }
      end
      conn = setup_conn(conn, %{"origin" => stop.id, "show_all_trips" => "true"}, schedules, [], now)

      assert conn.assigns.stop_times == StopTimeList.build(schedules, [], stop.id, nil, true)
    end
  end
end
