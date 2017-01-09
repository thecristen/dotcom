defmodule Predictions.Parser do
  alias Predictions.Prediction

  def parse(%JsonApi.Item{attributes: attributes, relationships: relationships} = item) do
    %Prediction{
      route_id: List.first(relationships["route"]).id,
      stop_id: stop_id(relationships["stop"]),
      trip: trip(item),
      direction_id: attributes["direction_id"],
      time: [attributes["departure_time"], attributes["arrival_time"]] |> first_time,
      schedule_relationship: schedule_relationship(attributes["schedule_relationship"]),
      track: attributes["track"],
      status: attributes["status"],
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

  defp schedule_relationship("ADDED"), do: :added
  defp schedule_relationship("UNSCHEDULED"), do: :unscheduled
  defp schedule_relationship("CANCELLED"), do: :cancelled
  defp schedule_relationship("SKIPPED"), do: :skipped
  defp schedule_relationship("NO_DATA"), do: :no_data
  defp schedule_relationship(_), do: nil

  defp trip(%JsonApi.Item{relationships: %{"trip" => []}}) do
    nil
  end
  defp trip(item) do
    Schedules.Parser.trip(item)
  end
end
