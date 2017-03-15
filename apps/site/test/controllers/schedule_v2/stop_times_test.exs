defmodule Site.ScheduleV2Controller.StopTimesTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.StopTimes
  import Plug.Conn, only: [assign: 3, fetch_query_params: 1]
  import UrlHelpers, only: [update_url: 2]

  alias Routes.Route
  alias Schedules.{Schedule, Trip, Stop}
  alias Predictions.Prediction

 @route %Route{id: "86", type: 3, name: "86"}
 @date_time ~N[2017-02-11T22:30:00]
 @cal_date  ~D[2017-02-11]

  describe "init/1" do
    test "takes no options" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    defp setup_conn(route, schedules, predictions, now, selected_date, origin, destination, show_all_trips \\ "false") do
      %{build_conn() | params: %{"show_all_trips" => show_all_trips}}
      |> assign(:route, route)
      |> assign(:direction_id, 0)
      |> assign(:schedules, schedules)
      |> assign(:predictions, predictions)
      |> assign(:date_time, now)
      |> assign(:date, selected_date)
      |> assign(:origin, origin)
      |> assign(:destination, destination)
      |> fetch_query_params
      |> call([])
    end

    test "assigns stop_times even without schedules or predictions" do
      conn = setup_conn(@route, [], [], @date_time, @cal_date, nil, nil)

      assert conn.assigns.stop_times == %StopTimeList{times: []}
    end

    test "Does not initially show all trips for Ferry" do
      conn = setup_conn(%Route{id: "Boat-F4", type: 4, name: "Boaty McBoatface"}, [], [], @date_time, @cal_date, nil, nil)

      assert conn.assigns.stop_times == %StopTimeList{times: []}
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

      assert conn.assigns.stop_times.times == StopTimeList.build(Enum.drop(schedules, 2), [], stop.id, nil, :last_trip_and_upcoming, now, true).times
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

      assert conn.assigns.stop_times == StopTimeList.build(schedules, [], stop.id, nil, :keep_all, @date_time, true)
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

    test "assigns prediction-only stop_times", %{conn: conn} do
      stop = %Stop{id: "stop"}
      trip = %Trip{id: "trip"}
      schedules = [%Schedule{trip: trip, stop: stop, time: @date_time}]
      predictions = [%Prediction{trip: trip, stop: stop, time: @date_time}]
      conn = conn
      |> assign(:route, %Routes.Route{type: 1})
      |> assign(:schedules, schedules)
      |> assign(:predictions, predictions)
      |> assign(:origin, stop)
      |> assign(:destination, nil)
      |> fetch_query_params
      |> call([])

      assert conn.assigns.stop_times == StopTimeList.build_predictions_only(
        schedules, predictions, "stop", nil)
    end

    test "if the assigned direction_id does not match the trip, redirects to the correct direction_id" do
      trip = %Trip{id: "trip", direction_id: 1}
      origin = %Stop{id: "origin"}
      destination = %Stop{id: "destination"}
      schedules = [
        {%Schedule{trip: trip, stop: origin, time: @date_time},
         %Schedule{trip: trip, stop: destination, time: @date_time}}]
      predictions = [
        %Prediction{stop: origin, time: @date_time},
        %Prediction{stop: destination, time: @date_time}]
      conn = setup_conn(@route, schedules, predictions, @date_time, @cal_date, origin, destination)
      assert redirected_to(conn, 302) == update_url(conn, direction_id: 1)
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
        %Prediction{trip: %Trip{id: "trip-#{hour}"}, stop: destination}
      end
      # Predictions that should be filtered out
      extra_predictions = for hour <- [4, 5, 6] do
        %Prediction{trip: %Trip{id: "trip-#{hour}"}, stop: elsewhere}
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
        @date_time,
        true
      )
    end
  end
end
