defmodule Site.ScheduleView.Alerts do

  def trip_alerts_for(_, []), do: []
  def trip_alerts_for(alerts, [schedule|_] = schedules) do
    trip_ids = schedules
    |> Enum.map(fn schedule -> schedule.trip.id end)

    Alerts.Trip.match(
      alerts,
      trip_ids,
      time: schedule.time,
      route: schedule.route.id,
      route_type: schedule.route.type,
      direction_id: schedule.trip.direction_id,
      stop: schedule.stop.id
    )
  end
  def trip_alerts_for(alerts, schedule) do
    trip_alerts_for(alerts, [schedule])
  end

  @doc """
  Partition a enum of alerts into a pair of those that should be displayed as notices, and those
  that should be displayed as alerts.
  """
  def notices_and_alerts(alerts) do
    alerts
    |> Enum.partition(&Alerts.Alert.is_notice?/1)
  end

  @doc """
  Takes a list of alerts and returns a string summarizing their effects, such as "3 Delays, Stop
  Closure, 4 Station Issues". Adds an optional suffix if the list of alerts is non-empty.
  """
  def display_alert_effects(alerts, suffix \\ "")
  def display_alert_effects([], _), do: ""
  def display_alert_effects(alerts, suffix) do
    alerts
    |> Enum.group_by(&(&1.effect_name))
    |> Enum.map(fn {effect_name, alerts} ->
      num_alerts = length(alerts)
      if num_alerts > 1 do
        "#{num_alerts} #{Inflex.inflect(effect_name, num_alerts)}"
      else
        effect_name
      end
    end)
    |> Enum.join(", ")
    |> Kernel.<>(suffix)
  end

  def display_alert_updated(alert) do
    {:ok, formatted} = alert.updated_at
    |> Timex.Format.DateTime.Formatters.Relative.relative_to(Util.now, "{relative}")

    "Updated #{formatted}"
  end
end
