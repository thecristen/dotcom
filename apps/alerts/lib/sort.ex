defmodule Alerts.Sort do
  @moduledoc """

  Sorts alerts in order of relevance.  Currently, the logic is:

  * effect name
  * lifecycle
  * severity
  * updated at (newest first)
  * future affected period (closest first)
  * id

  """

  @severity_order [
    "Severe",
    "Significant",
    "Moderate",
    "Minor",
    "Information"
  ]

  @lifecycle_order [
    "New",
    "Upcoming",
    "Ongoing-Upcoming",
    "Ongoing"
  ]

  @effect_name_order [
    "Amber Alert",
    "Cancellation",
    "Delay",
    "Suspension",
    "Track Change",
    "Detour",
    "Shuttle",
    "Stop Closure",
    "Dock Closure",
    "Station Closure",
    "Stop Move",
    "Extra Service",
    "Schedule Change",
    "Service Change",
    "Snow Route",
    "Station Issue",
    "Dock Issue",
    "Access Issue",
    "Policy Change"
  ]

  def sort(alerts, now) do
    Enum.sort_by(alerts, &sort_key(&1, now))
  end

  defp sort_key(alert, now) do
    {
      effect_name_index(alert.effect_name),
      lifecycle_index(alert.lifecycle),
      severity_index(alert.severity),
      -updated_at_date(alert.updated_at),
      first_future_active_period_start(alert.active_period, now),
      alert.id
    }
  end

  # generate methods for looking up the indexes, rather than having to
  # traverse the list each time
  for {severity, index} <- Enum.with_index(@severity_order) do
    defp severity_index(unquote(severity)), do: unquote(index)
  end
  # fallback
  defp severity_index(_), do: unquote(length(@severity_order))

  for {lifecycle, index} <- Enum.with_index(@lifecycle_order) do
    defp lifecycle_index(unquote(lifecycle)), do: unquote(index)
  end
  # fallback
  defp lifecycle_index(_), do: unquote(length(@effect_name_order))

  for {name, index} <- Enum.with_index(@effect_name_order) do
    defp effect_name_index(unquote(name)), do: unquote(index)
  end
  # fallback
  defp effect_name_index(_), do: unquote(length(@effect_name_order))

  defp updated_at_date(dt) do
    dt
    |> Timex.beginning_of_day
    |> Timex.to_unix
  end

  defp first_future_active_period_start([], _now), do: :infinity # atoms are greater than any integer
  defp first_future_active_period_start(periods, now) do
    # first active period that's in the future
    now_unix = DateTime.to_unix(now, :second)
    future_periods = periods
    |> Enum.filter_map(fn {start, _} -> start != nil end, fn {start, _} -> start end)
    |> Enum.map(&Timex.to_unix/1)
    |> Enum.filter(&(&1 > now_unix))

    case future_periods do
      [] -> :infinity
      list -> Enum.min(list)
    end
  end
end
