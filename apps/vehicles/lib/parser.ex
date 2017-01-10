defmodule Vehicles.Parser do
  alias Vehicles.Vehicle

  @spec parse(JsonApi.Item.t) :: Vehicle.t
  def parse(%JsonApi.Item{id: id, attributes: attributes, relationships: relationships}) do
    %Vehicle{
      id: id,
      route_id: List.first(relationships["route"]).id,
      trip_id: trip_id(relationships["trip"]),
      stop_id: List.first(relationships["stop"]).id,
      direction_id: attributes["direction_id"],
      status: status(attributes["current_status"])
    }
  end

  @spec status(String.t) :: Vehicle.status
  defp status("STOPPED_AT"), do: :stopped
  defp status("INCOMING_AT"), do: :incoming
  defp status("IN_TRANSIT_TO"), do: :in_transit

  @spec trip_id([JsonApi.Item.t]) :: String.t | nil
  defp trip_id(nil), do: nil
  defp trip_id([%{id: id}]), do: id
end
