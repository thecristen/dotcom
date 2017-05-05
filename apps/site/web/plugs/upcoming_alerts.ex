defmodule Site.Plugs.UpcomingAlerts do
  @moduledoc """
  Assigns some variables to the conn for relevant alerts:
  Expects all_alerts to have assignment

  * alerts: currently valid alerts/notices (current based on date parameter)
  * upcoming alerts: alerts/notices that will be valid some other time
  """
  import Plug.Conn, only: [assign: 3]

  def init(_opts) do
    []
  end

  def call(%{assigns: %{all_alerts: all_alerts, date: date}} = conn, _opts) do
    {current_alerts, not_current_alerts} = all_alerts
    |> Enum.partition(fn alert -> Alerts.Match.any_time_match?(alert, date) end)
      upcoming_alerts = not_current_alerts
      |> Enum.filter(fn alert ->
        Enum.any?(alert.active_period, fn
          {nil, nil} ->
            true
          {nil, stop} ->
            not Timex.before?(date, stop)
          {start, _} ->
            Timex.before?(date, start)
        end)
      end)

    conn
    |> assign(:alerts, current_alerts)
    |> assign(:upcoming_alerts, upcoming_alerts)
  end
  def call(conn, _opts) do
    conn
  end
end
