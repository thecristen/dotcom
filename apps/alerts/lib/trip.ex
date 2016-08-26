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
    all_trip_entities = trip_ids
    |> Enum.map(&(entity_for(&1, options)))
    all_trip_alerts = Alerts.Match.match(
      alerts,
      all_trip_entities,
      options[:time])

    [all_trip_alerts,
     delay_alerts(alerts, options)]
    |> Enum.concat
    |> Enum.uniq
  end
  def match(alerts, trip_id, options) do
    [trip_alerts(alerts, trip_id, options[:time]),
     delay_alerts(alerts, options)
    ]
    |> Enum.concat
    |> Enum.uniq
  end

  defp trip_alerts(alerts, trip_id, time) do
    alerts
    |> Alerts.Match.match(entity_for(trip_id, []), time)
  end

  defp delay_alerts(alerts, options) do
    alerts
    |> Alerts.Match.match(entity_for(nil, options), options[:time])
    |> Enum.filter(&(&1.effect_name in ["Delay", "Suspension"]))
  end

  defp entity_for(trip_id, options) do
    entity = %Alerts.InformedEntity{trip: trip_id}
    [:stop, :route, :route_type, :direction_id]
    |> Enum.reduce(entity, fn key, entity ->
      case Keyword.fetch(options, key) do
        {:ok, value} -> Alerts.InformedEntity.put(entity, key, value)
        :error -> entity
      end
    end)
  end
end
