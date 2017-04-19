defmodule Alerts.Parser do
  defmodule Alert do
    @spec parse(JsonApi.Item.t) :: Alerts.Alert.t
    def parse(%JsonApi.Item{type: "alert", id: id, attributes: attributes}) do
      %Alerts.Alert{
        id: id,
        header: attributes["header"],
        informed_entity: parse_informed_entity(attributes["informed_entity"]),
        active_period:  Enum.map(attributes["active_period"], &active_period/1),
        effect_name: attributes["effect_name"],
        severity: attributes["severity"],
        lifecycle: attributes["lifecycle"],
        updated_at: parse_time(attributes["updated_at"]),
        description: description(attributes["description"])
      }
    end

    defp parse_informed_entity(informed_entities) do
      informed_entities
      |> Enum.flat_map(&informed_entity/1)
      |> Enum.uniq()
    end

    defp informed_entity(%{"route" => "Green" <> _} = entity) do
      [do_informed_entity(entity), do_informed_entity(%{entity | "route" => "Green"})]
    end
    defp informed_entity(entity) do
      [do_informed_entity(entity)]
    end

    defp do_informed_entity(entity) do
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

    # remove leading/trailing whitespace from description
    defp description(nil) do
      nil
    end
    defp description(str) do
      case String.trim(str) do
        "" -> nil
        str -> str
      end
    end
  end

  defmodule Banner do
    @spec parse(JsonApi.Item.t) :: [Alerts.Banner.t]
    def parse(%JsonApi.Item{
          id: id,
          attributes: %{
            "url" => url,
            "banner" => title
          }}) when title != nil do
      [
        %Alerts.Banner{
          id: id,
          title: title,
          url: url}
      ]
    end
    def parse(%JsonApi.Item{}) do
      []
    end
  end
end
