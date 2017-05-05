defmodule Routes.Parser do
  @spec parse_route(JsonApi.Item.t) :: Routes.Route.t
  def parse_route(%JsonApi.Item{id: id, attributes: attributes}) do
    %Routes.Route{
      id: id,
      type: attributes["type"],
      name: name(attributes),
      direction_names: direction_names(attributes["direction_names"]),
      key_route?: key_route?(name(attributes), attributes["description"])
    }
  end

  defp name(%{"type" => 3, "short_name" => short_name}), do: short_name
  defp name(%{"short_name" => short_name, "long_name" => ""}), do: short_name
  defp name(%{"long_name" => long_name}), do: long_name

  defp direction_names([zero, one]) do
    %{0 => zero, 1 => one}
  end

  defp key_route?(_, "Key Bus Route (Frequent Service)"), do: true
  defp key_route?(name, "Rapid Transit") when name != "Mattapan Trolley", do: true
  defp key_route?(_, _), do: false

  @spec parse_shape(JsonApi.Item.t) :: [Routes.Shape.t]
  def parse_shape(%JsonApi.Item{attributes: %{"priority" => priority}}) when priority < 0 do
    # ignore shapes with a negative priority
    []
  end
  def parse_shape(%JsonApi.Item{id: id, attributes: attributes, relationships: relationships}) do
    [%Routes.Shape{
        id: id,
        name: attributes["name"],
        stop_ids: Enum.map(relationships["stops"], & &1.id),
        direction_id: attributes["direction_id"],
        polyline: attributes["polyline"]
    }]
  end
end
