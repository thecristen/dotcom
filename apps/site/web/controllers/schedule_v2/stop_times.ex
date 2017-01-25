defmodule Site.ScheduleV2Controller.StopTimes do
  @moduledoc """
  Assigns a list of stop times based on predictions, schedules, origin, and destination. The bulk of
  the work happens in StopTimeList.
  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []
  
  def call(%Plug.Conn{assigns: %{route: %Routes.Route{type: route_type}}} = conn, _) when route_type in [0, 1] do
    stop_times = StopTimeList.build_predictions_only(
      conn.assigns.predictions,
      conn.params["origin"],
      conn.params["destination"]
    )
    assign(conn, :stop_times, stop_times)
  end

  def call(conn, []) do
    stop_times = StopTimeList.build(
      conn.assigns.schedules,
      conn.assigns.predictions,
      conn.params["origin"],
      conn.params["destination"],
      conn.params["show_all_trips"] == "true"
    )
    assign(conn, :stop_times, stop_times)
  end
end
