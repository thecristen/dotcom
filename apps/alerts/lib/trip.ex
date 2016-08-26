defmodule Alerts.Trip do

  @doc """

  Given a trip_id, returns the list of alerts which apply to that trip.

  Options include:

  * stop: for a particular stop along that trip (ID string)
  * route: the route that trip is on (ID string)
  * route_type: the type of route (GTFS integer)
  * direction_id: the direction of the trip (GTFS integer)
  * time: for a particular time during that trip (DateTime)

  """
  def match(alerts, trip_id, options \\ []) do
    trip_alerts = alerts
    |> Alerts.Match.match(entity_for(trip_id, []), options[:time])

    delay_alerts = alerts
    |> Alerts.Match.match(entity_for(nil, options), options[:time])
    |> Enum.filter(&(&1.effect_name in ["Delay", "Suspension"]))

    trip_alerts
    |> Kernel.++(delay_alerts)
    |> Enum.uniq
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
