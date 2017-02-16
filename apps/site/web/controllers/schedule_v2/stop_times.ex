defmodule Site.ScheduleV2Controller.StopTimes do
  @moduledoc """
  Assigns a list of stop times based on predictions, schedules, origin, and destination. The bulk of
  the work happens in StopTimeList.
  """
  import Plug.Conn, only: [assign: 3]

  require Routes.Route
  alias Routes.Route

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: %Routes.Route{type: route_type}}} = conn, []) when Route.subway?(route_type) do
    destination_id = Util.safe_id(conn.assigns.destination)
    origin_id = Util.safe_id(conn.assigns.origin)
    predictions = conn.assigns.predictions

    stop_times = StopTimeList.build_predictions_only(predictions, origin_id, destination_id)

    assign(conn, :stop_times, stop_times)
  end

  def call(%Plug.Conn{assigns: %{route: %Routes.Route{type: route_type}, schedules: schedules}} = conn, []) do
    show_all_trips? = conn.params["show_all_trips"] == "true"
    destination_id = Util.safe_id(conn.assigns.destination)
    origin_id = Util.safe_id(conn.assigns.origin)
    predictions = conn.assigns.predictions
    current_time = conn.assigns.date_time
    user_selected_date = conn.assigns.date
    current_date_time = conn.assigns.date_time
    filter_flag = filter_flag(user_selected_date, current_date_time, route_type, show_all_trips?)

    stop_times =
      StopTimeList.build(schedules, predictions, origin_id, destination_id, filter_flag, current_time)

    assign(conn, :stop_times, stop_times)
  end

  def call(conn, []) do
    conn
  end

  defp filter_flag(user_selected_date, current_date_time, route_type, show_all) do
    cond do
      Timex.diff(user_selected_date, current_date_time, :days) == 0 ->
        filter_flag_for_today(route_type, show_all)
      true ->
        :keep_all
    end
  end

  defp filter_flag_for_today(2, false), do: :last_trip_and_upcoming
  defp filter_flag_for_today(3, false), do: :predictions_then_schedules
  defp filter_flag_for_today(_route_type, _show_all), do: :keep_all
end
