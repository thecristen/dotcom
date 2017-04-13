defmodule Predictions.Parser do
  alias Predictions.Prediction

  @spec parse(JsonApi.Item.t) :: Prediction.t
  def parse(%JsonApi.Item{attributes: attributes, relationships: relationships} = item) do
    %Prediction{
      id: item.id,
      route: route(List.first(relationships["route"])),
      stop: stop(relationships["stop"]),
      trip: trip(item),
      direction_id: attributes["direction_id"],
      time: [attributes["departure_time"], attributes["arrival_time"]] |> first_time,
      stop_sequence: attributes["stop_sequence"] || 0,
      schedule_relationship: schedule_relationship(attributes["schedule_relationship"]),
      track: attributes["track"],
      status: attributes["status"],
      departing?: departing?(attributes)
    }
  end

  defp first_time(times) do
    case times
    |> Enum.reject(&is_nil/1)
    |> List.first
    |> Timex.parse("{ISO:Extended}") do
      {:ok, time} -> time
      _ -> nil
    end
  end

  defp departing?(%{"departure_time" => binary}) when is_binary(binary) do
    true
  end
  defp departing?(_) do
    false
  end

  defp stop([stop | _]) do
    case stop.relationships["parent_station"] do
      [%{id: parent_id, attributes: %{"name" => parent_name}} | _] -> %Schedules.Stop{name: parent_name, id: parent_id}
      _ -> %Schedules.Stop{id: stop.id, name: stop.attributes["name"]}
    end
  end

  @spec schedule_relationship(String.t) :: Prediction.schedule_relationship
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

  defp route(item) do
    Routes.Parser.parse_route(item)
  end
end
