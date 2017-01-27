defmodule Site.ScheduleV2Controller.StopTimes do
  @moduledoc """
  Assigns a list of stop times based on predictions, schedules, origin, and destination. The bulk of
  the work happens in StopTimeList.
  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: %Routes.Route{type: route_type}, schedules: _schedules}} = conn, _) when route_type in [0, 1] do
    stop_times = StopTimeList.build_predictions_only(
      conn.assigns.predictions,
      conn.params["origin"],
      conn.params["destination"]
    )
    assign(conn, :stop_times, stop_times)
  end
  def call(%Plug.Conn{assigns: %{schedules: _schedules}} = conn, []) do
    show_all_trips? = conn.params["show_all_trips"] == "true"
    stop_times = StopTimeList.build(
      filtered_schedules(conn.assigns, show_all_trips?),
      conn.assigns.predictions,
      conn.params["origin"],
      conn.params["destination"],
      show_all_trips?
    )
    assign(conn, :stop_times, stop_times)
  end
  def call(conn, []) do
    conn
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
  defp after_now?(%Schedules.Schedule{time: time}, date_time) do
    Timex.after?(time, date_time)
  end
end
