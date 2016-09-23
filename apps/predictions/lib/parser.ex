defmodule Predictions.Parser do
  alias Predictions.Prediction

  def parse(%{attributes: attributes, relationships: relationships}) do
    %Prediction{
      route_id: List.first(relationships["route"]).id,
      stop_id: stop_id(relationships["stop"]),
      trip_id: List.first(relationships["trip"]).id,
      direction_id: attributes["direction_id"],
      time: [attributes["arrival_time"], attributes["departure_time"]] |> first_time,
      track: attributes["track"],
      status: attributes["status"]
    }
  end

  defp first_time(times) do
    times
    |> Enum.reject(&is_nil/1)
    |> List.first
    |> Timex.parse!("{ISO:Extended}")
  end

  defp stop_id([stop | _]) do
    case stop.relationships["parent_station"] do
      [%{id: parent_id} | _] -> parent_id
      _ -> stop.id
    end
  end
end
