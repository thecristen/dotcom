defmodule Routes.Repo do
  def all do
    V3Api.Routes.all.data
    |> Enum.map(&parse_json/1)
  end

  defp parse_json(%JsonApi.Item{id: id, attributes: attributes}) do
    %Routes.Route{
      id: id,
      type: attributes["type"],
      name: name(attributes)
    }
  end

  defp name(%{"long_name" => "", "short_name" => short_name}), do: short_name
  defp name(%{"long_name" => long_name}), do: long_name
end
