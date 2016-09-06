defmodule Alerts.Parser do
  def parse(%JsonApi.Item{type: "alert", id: id, attributes: attributes}) do
    %Alerts.Alert{
      id: id,
      header: attributes["header"],
      informed_entity: attributes["informed_entity"] |> Enum.map(&informed_entity/1),
      active_period: attributes["active_period"] |> Enum.map(&active_period/1),
      effect_name: attributes["effect_name"],
      severity: attributes["severity"],
      lifecycle: attributes["lifecycle"],
      updated_at: parse_time(attributes["updated_at"]),
      description: attributes["description"]
    }
  end

  defp informed_entity(entity) do
    # since lookups default to nil, this results in the correct data
    %Alerts.InformedEntity{
      route_type: entity["route_type"],
      route: entity["route"],
      stop: entity["stop"],
      trip: entity["trip"],
      direction_id: entity["direction_id"]
    }
  end

  defp active_period(%{"start" => start, "end" => stop}) do
    {parse_time(start), parse_time(stop)}
  end

  defp parse_time(nil) do
    nil
  end
  defp parse_time(str) do
    str
    |> Timex.parse!("{ISO:Extended}")
  end
end
