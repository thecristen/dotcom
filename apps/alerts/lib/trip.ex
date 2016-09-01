defmodule Alerts.Trip do

  @doc """

  Given a trip_id (or a list of IDs), returns the list of alerts which apply
  to that trip.

  Options include:

  * stop: for a particular stop along that trip (ID string)
  * route: the route that trip is on (ID string)
  * route_type: the type of route (GTFS integer)
  * direction_id: the direction of the trip (GTFS integer)
  * time: for a particular time during that trip (DateTime)

  """
  def match(alerts, trip_ids, options \\ [])
  def match(alerts, trip_ids, options) when is_list(trip_ids) do
    [trip_alerts(alerts, trip_ids, options[:time]),
     delay_alerts(alerts, options)]
    |> Enum.concat
    |> Enum.uniq
  end
  def match(alerts, trip_id, options) do
    match(alerts, [trip_id], options)
  end

  defp trip_alerts(alerts, trip_ids, time) do
    trip_entities = trip_ids
    |> Enum.map(&(%Alerts.InformedEntity{trip: &1}))

    alerts
    |> Alerts.Match.match(trip_entities, time)
  end

  defp delay_alerts(alerts, options) do
    entity = Alerts.InformedEntity.from_keywords(options)

    alerts
    |> Enum.filter(&alert_is_delay?/1)
    |> Alerts.Match.match(entity, options[:time])
  end

  defp alert_is_delay?(alert)
  defp alert_is_delay?(%{effect_name: "Delay"}), do: true
  defp alert_is_delay?(%{effect_name: "Suspension"}), do: true
  defp alert_is_delay?(_), do: false

end
