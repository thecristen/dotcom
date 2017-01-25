defmodule Site.ScheduleV2.StopTimes do
  @moduledoc """
  Assigns a list of stop times based on predictions, schedules, origin, and destination. The bulk of
  the work happens in StopTimeList.
  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []
  
  def call(conn, []) do
    stop_times = StopTimeList.build(
      conn.assigns.schedules,
      conn.assigns.predictions,
      conn.assigns.origin,
      conn.assigns.destination,
      Map.get(conn.params, "show_all_trips") == "true"
    )
    assign(conn, :stop_times, stop_times)
  end
end
