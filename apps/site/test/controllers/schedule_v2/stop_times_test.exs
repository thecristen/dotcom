defmodule Site.ScheduleV2Controller.StopTimesTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.StopTimes
  import Plug.Conn, only: [assign: 3, fetch_query_params: 1]

  alias Routes.Route
  alias Schedules.{Schedule, Trip, Stop}

 @route %Route{id: "86", type: 3, name: "86"}
 @date_time ~N[2017-02-11T22:30:00]
 @cal_date  ~N[2017-02-11T12:00:00]

  describe "init/1" do
    test "takes no options" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    defp setup_conn(route, schedules, predictions, now, selected_date, origin, destination, show_all_trips \\ "false") do
      %{build_conn() | params: %{"show_all_trips" => show_all_trips}}
      |> assign(:route, route)
      |> assign(:schedules, schedules)
      |> assign(:predictions, predictions)
      |> assign(:date_time, now)
      |> assign(:date, selected_date)
      |> assign(:origin, origin)
      |> assign(:destination, destination)
      |> fetch_query_params
      |> call([])
    end

    test "assigns stop_times" do
      conn = setup_conn(@route, [], [], @date_time, @cal_date, nil, nil)

      assert conn.assigns.stop_times == %StopTimeList{times: [], showing_all?: false}
    end

    test "filters out schedules in the past by default, leaving the last entry before now" do
      now = ~N[2017-02-11T12:00:00]

      stop = %Stop{id: "stop"}
      schedules = for hour <- [-3, -2, -1, 1, 2, 3] do
        %Schedule{
          time: Timex.shift(now, hours: hour),
          trip: %Trip{id: "trip-#{hour}"},
          stop: stop
        }
      end
      conn = setup_conn(%Route{id: "CR-Lowell", type: 2, name: "Lowell"}, schedules, [], now, now, stop, nil)

      assert conn.assigns.stop_times == StopTimeList.build(Enum.drop(schedules, 2), [], stop.id, nil, :last_trip_and_upcoming, now)
    end

    test "if filter_flag is :keep_all is true, doesn't filter schedules" do
      now = @date_time
      stop = %Stop{id: "stop"}
      schedules = for hour <- [-3, -2, -1, 1, 2, 3] do
        %Schedule{
          time: Timex.shift(now, hours: hour),
          trip: %Trip{id: "trip-#{hour}"},
          stop: stop
        }
      end
      conn = setup_conn(@route, schedules, [], now, @cal_date, stop, nil, "true")

      assert conn.assigns.stop_times == StopTimeList.build(schedules, [], stop.id, nil, :keep_all, @date_time)
    end

    test "assigns stop_times for subway", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{type: 1})
      |> assign(:schedules, [])
      |> assign(:predictions, [])
      |> assign(:origin, nil)
      |> assign(:destination, nil)
      |> fetch_query_params
      |> call([])

      assert conn.assigns.stop_times != nil
    end

    test "filters out predictions belonging to a trip that doesn't go to the destination" do
      now = @date_time
      origin = %Stop{id: "origin"}
      destination = %Stop{id: "destination"}
      elsewhere = %Stop{id: "elsewhere"}
      # Schedules that go to the destination
      destination_schedules = for hour <- [1, 2, 3] do
        {
          %Schedule{
            time: Timex.shift(now, hours: hour),
            trip: %Trip{id: "trip-#{hour}"},
            stop: origin
          },
          %Schedule{
            time: Timex.shift(now, hours: hour + 1),
            trip: %Trip{id: "trip-#{hour}"},
            stop: destination
          }
        }
      end
      # Schedules that don't go through the destination
      extra_schedules = for hour <- [4, 5, 6] do
        {
          %Schedule{
            time: Timex.shift(now, hours: hour),
            trip: %Trip{id: "trip-#{hour}"},
            stop: origin
          },
          %Schedule{
            time: Timex.shift(now, hours: hour + 1),
            trip: %Trip{id: "trip-#{hour}"},
            stop: elsewhere
          }
        }
      end
      all_schedules = destination_schedules ++ extra_schedules

      # Predictions at the destination
      destination_predictions = for hour <- [1, 2, 3] do
        %Predictions.Prediction{trip: %Trip{id: "trip-#{hour}"}, stop: destination}
      end
      # Predictions that should be filtered out
      extra_predictions = for hour <- [4, 5, 6] do
        %Predictions.Prediction{trip: %Trip{id: "trip-#{hour}"}, stop: elsewhere}
      end

      conn = setup_conn(
        @route,
        all_schedules,
        destination_predictions ++ extra_predictions,
        now,
        @cal_date,
        origin,
        destination
      )

      assert conn.assigns.stop_times == StopTimeList.build(
        all_schedules,
        destination_predictions,
        origin.id,
        destination.id,
        :predictions_then_schedules,
        @date_time
      )
    end
  end
end
