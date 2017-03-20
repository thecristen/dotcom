defmodule Site.ScheduleV2Controller.StopTimes do
  @moduledoc """
  Assigns a list of stop times based on predictions, schedules, origin, and destination. The bulk of
  the work happens in StopTimeList.
  """
  use Plug.Builder
  import Plug.Conn, only: [assign: 3, halt: 1]
  import Phoenix.Controller, only: [redirect: 2]
  import UrlHelpers, only: [update_url: 2]

  require Routes.Route
  alias Routes.Route

  plug :assign_stop_times
  plug :validate_direction_id

  def assign_stop_times(%Plug.Conn{assigns: %{route: %Routes.Route{type: route_type}, schedules: schedules}} = conn, []) when Route.subway?(route_type) do
    destination_id = Util.safe_id(conn.assigns.destination)
    origin_id = Util.safe_id(conn.assigns.origin)
    predictions = conn.assigns.predictions

    stop_times = StopTimeList.build_predictions_only(schedules, predictions, origin_id, destination_id)

    assign(conn, :stop_times, stop_times)
  end
  def assign_stop_times(%Plug.Conn{assigns: %{route: %Routes.Route{type: route_type}, schedules: schedules}} = conn, []) do
    show_all_trips? = conn.params["show_all_trips"] == "true"
    destination_id = Util.safe_id(conn.assigns.destination)
    origin_id = Util.safe_id(conn.assigns.origin)
    predictions = conn.assigns.predictions
    user_selected_date = conn.assigns.date
    current_date_time = conn.assigns.date_time
    today? = Timex.diff(user_selected_date, current_date_time, :days) == 0
    current_time = if today?, do: conn.assigns.date_time, else: nil
    filter_flag = filter_flag(today?, route_type)
    keep_all? = keep_all?(today?, route_type, show_all_trips?)

    stop_times =
      StopTimeList.build(schedules, predictions, origin_id, destination_id, filter_flag, current_time, keep_all?)

    assign(conn, :stop_times, stop_times)
  end
  def assign_stop_times(conn, []) do
    conn
  end

  def validate_direction_id(%Plug.Conn{assigns: %{direction_id: direction_id, stop_times: stop_times}} = conn, []) do
    case Enum.find(stop_times.times, &!is_nil(&1.trip)) do
      nil ->
        conn
      stop_time ->
        if stop_time.trip.direction_id != direction_id do
          url = update_url(conn, direction_id: stop_time.trip.direction_id)
          conn
          |> redirect(to: url)
          |> halt
        else
          conn
        end
    end
  end
  def validate_direction_id(conn, []) do
    conn
  end

  defp keep_all?(today?, route_type, show_all?) do
    show_all? || !today? || Route.subway?(route_type)
  end

  defp filter_flag(_today?, 3), do: :predictions_then_schedules
  defp filter_flag(_today?, _route_type), do: :last_trip_and_upcoming
end
