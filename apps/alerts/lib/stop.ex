defmodule Alerts.Stop do
  @moduledoc """

  Given a stop_id, returns the list of alerts which apply to that stop.

  Options include:

  * route: the route we're interested in (ID string)
  * route_type: the route_type of the interested route (GTFS integer)
  * direction_id: the direction we're travelling (GTFS integer)
  * time: for a particular datetime (DateTime)
  """
  alias Alerts.InformedEntity, as: IE
  alias Alerts.Match

  def match(alerts, stop_id, options \\ []) do
    # First, we filter the alerts to those that match any of the options
    # including the stop.  Then, we filter again to get only those that
    # explicitly use the stop.
    alerts
    |> Match.match(entity_for(stop_id, options), options[:time])
    |> Match.match(entity_for(stop_id, []))
  end

  defp entity_for(stop_id, options) do
    entity = %IE{stop: stop_id}
    [:route, :route_type, :direction_id]
    |> Enum.reduce(entity, fn key, entity ->
      case Keyword.fetch(options, key) do
        {:ok, value} -> IE.put(entity, key, value)
        :error -> entity
      end
    end)
  end
end
