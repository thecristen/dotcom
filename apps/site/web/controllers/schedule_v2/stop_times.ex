defmodule Site.ScheduleV2Controller.StopTimes do
  @moduledoc """
  Assigns a list of stop times based on predictions, schedules, origin, and destination. The bulk of
  the work happens in StopTimeList.
  """
  import Plug.Conn, only: [assign: 3]

  alias Schedules.{Schedule, Trip, Stop}
  alias Predictions.Prediction

  require Routes.Route
  alias Routes.Route

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: %Routes.Route{type: route_type}, schedules: schedules}} = conn, []) when Route.subway?(route_type) do
    destination_id = stop_id(conn.assigns.destination)
    origin_id = stop_id(conn.assigns.origin)
    stop_times = StopTimeList.build_predictions_only(
      filtered_predictions(conn.assigns.predictions, schedules, destination_id),
      origin_id,
      destination_id
    )
    assign(conn, :stop_times, stop_times)
  end
  def call(%Plug.Conn{assigns: %{schedules: schedules}} = conn, []) do
    show_all_trips? = conn.params["show_all_trips"] == "true"
    destination_id = stop_id(conn.assigns.destination)
    origin_id = stop_id(conn.assigns.origin)
    stop_times = StopTimeList.build(
      filtered_schedules(conn.assigns, show_all_trips?),
      filtered_predictions(conn.assigns.predictions, schedules, destination_id),
      origin_id,
      destination_id,
      show_all_trips?
    )
    assign(conn, :stop_times, stop_times)
  end
  def call(conn, []) do
    conn
  end

  # Remove any predictions for trips that don't go through the
  # destination stop, by checking the list of schedules to ensure that
  # there's an O/D pair for each prediction's trip.
  defp filtered_predictions(predictions, _schedules, nil), do: predictions
  defp filtered_predictions(predictions, schedules, destination) do
    schedule_pair_trip_ids = MapSet.new(
      schedules,
      fn
        {_, %Schedule{trip: %Trip{id: trip_id}, stop: %Stop{id: ^destination}}} -> trip_id
        _ -> nil
      end
    )

    Enum.filter(
      predictions,
      fn
        %Prediction{trip: nil} -> false
        %Prediction{stop_id: ^destination} -> true
        %Prediction{trip: %Trip{id: trip_id}} -> trip_id in schedule_pair_trip_ids
      end
    )
  end

  defp filtered_schedules(%{schedules: schedules, date_time: date_time}, show_all_trips?) do
    schedules
    |> upcoming_schedules(show_all_trips?, date_time)
  end

  defp upcoming_schedules(schedules, true, _date_time) do
    schedules
  end
  defp upcoming_schedules(schedules, false, date_time) do
    do_upcoming_schedules(schedules, date_time)
  end

  defp do_upcoming_schedules([_first, second | rest] = schedules, date_time) do
    if after_now?(second, date_time) do
      schedules
    else
      do_upcoming_schedules([second | rest], date_time)
    end
  end
  defp do_upcoming_schedules(schedules, _date_time) do
    schedules
  end

  defp after_now?({_, arrival}, date_time) do
    after_now?(arrival, date_time)
  end
  defp after_now?(%Schedule{time: time}, date_time) do
    Timex.after?(time, date_time)
  end

  defp stop_id(%{id: id}), do: id
  defp stop_id(_), do: nil
end
