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
    {current_alerts, upcoming_alerts} = Alerts.Partition.current_and_upcoming(all_alerts, date)
    conn
    |> assign(:alerts, current_alerts)
    |> assign(:upcoming_alerts, upcoming_alerts)
  end
  def call(conn, _opts) do
    conn
  end
end
