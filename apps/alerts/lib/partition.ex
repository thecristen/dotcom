defmodule Alerts.Partition do
  @moduledoc """
  Functions for grouping Alerts
  """
  alias Alerts.Alert

  @doc """
  Separates current and upcoming alerts based on the given date
  """
  @spec current_and_upcoming([Alert.t], DateTime.t) :: {[Alert.t], [Alert.t]}
  def current_and_upcoming(alerts, date) do
    {current_alerts, upcoming_alerts} = alerts
    |> Enum.partition(fn alert -> Alerts.Match.any_time_match?(alert, date) end)

    {current_alerts, upcoming_alerts(upcoming_alerts, date)}
  end

  defp upcoming_alerts(upcoming_alerts, date) do
    any_active? = fn alert -> Enum.any?(alert.active_period, &active_alert?(&1, date)) end
    Enum.filter(upcoming_alerts, any_active?)
  end

  defp active_alert?({nil, nil}, _date), do: true
  defp active_alert?({nil, stop}, date), do: not Timex.before?(date, stop)
  defp active_alert?({start, _}, date), do: Timex.before?(date, start)
end
