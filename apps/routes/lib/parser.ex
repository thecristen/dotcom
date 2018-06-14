defmodule Routes.Parser do
  @spec parse_route(JsonApi.Item.t) :: Routes.Route.t
  def parse_route(%JsonApi.Item{id: id, attributes: attributes}) do
    %Routes.Route{
      id: id,
      type: attributes["type"],
      name: name(attributes),
      direction_names: direction_names(attributes["direction_names"]),
      description: parse_gtfs_desc(attributes["description"]),
    }
  end

  defp name(%{"type" => 3, "short_name" => short_name}) when short_name != "", do: short_name
  defp name(%{"short_name" => short_name, "long_name" => ""}), do: short_name
  defp name(%{"long_name" => long_name}), do: long_name

  defp direction_names([zero, one]) do
    %{0 => zero, 1 => one}
  end

  @spec parse_gtfs_desc(String.t) :: Routes.Route.gtfs_route_desc
  defp parse_gtfs_desc(description)
  defp parse_gtfs_desc("Airport Shuttle"), do: :airport_shuttle
  defp parse_gtfs_desc("Commuter Rail"), do: :commuter_rail
  defp parse_gtfs_desc("Rapid Transit"), do: :rapid_transit
  defp parse_gtfs_desc("Local Bus"), do: :local_bus
  defp parse_gtfs_desc("Key Bus Route (Frequent Service)"), do: :key_bus_route
  defp parse_gtfs_desc("Limited Service"), do: :limited_service
  defp parse_gtfs_desc("Express Bus"), do: :express_bus
  defp parse_gtfs_desc("Ferry"), do: :ferry
  defp parse_gtfs_desc("Rail Replacement Bus"), do: :rail_replacement_bus
  defp parse_gtfs_desc(_), do: :unknown

  @spec parse_shape(JsonApi.Item.t) :: [Routes.Shape.t]
  def parse_shape(%JsonApi.Item{id: id, attributes: attributes, relationships: relationships}) do
    [%Routes.Shape{
        id: id,
        name: attributes["name"],
        stop_ids: Enum.map(relationships["stops"], & &1.id),
        direction_id: attributes["direction_id"],
        polyline: attributes["polyline"],
        priority: attributes["priority"]
    }]
  end
end
