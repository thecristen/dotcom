defmodule Site.ScheduleView.Alerts do

  def alerts_for(alerts, %Schedules.Schedule{} = schedule) do
    entity = %Alerts.InformedEntity{
      route_type: schedule.route.type,
      route: schedule.route.id,
      stop: schedule.stop.id,
      trip: schedule.trip.id
    }

    alerts
    |> Alerts.Match.match(entity, schedule.time)
  end

  def alerts_for(alerts, %Schedules.Trip{} = trip) do
    entity = %Alerts.InformedEntity{
      trip: trip.id
    }

    alerts
    |> Alerts.Match.match(entity)
  end

  def has_alerts?(alerts, item) do
    matched = alerts
    |> alerts_for(item)
    |> Enum.reject(&Alerts.Alert.is_notice?/1)

    matched != []
  end

  def trip_alerts_for(alerts, schedules) when is_list(schedules) do
    schedules
    |> Enum.flat_map(&(trip_alerts_for(alerts, &1)))
    |> Enum.uniq
  end
  def trip_alerts_for(alerts, schedule) do
    alerts
    |> Alerts.Trip.match(
      schedule.trip.id,
      time: schedule.time,
      route: schedule.route.id,
      route_type: schedule.route.type,
      direction_id: schedule.trip.direction_id,
      stop: schedule.stop.id)
  end

  def has_trip_alerts?(alerts, schedules) do
    trip_alerts_for(alerts, schedules) != []
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
