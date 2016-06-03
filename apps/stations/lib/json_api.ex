defmodule JsonApi.Item do
  defstruct [:type, :id, :attributes, :relationships]
end

defmodule JsonApi do
  defstruct [:links, :data]

  @spec parse(String.t) :: JsonApi
  def parse(body) do
    with {:ok, parsed} <- Poison.Parser.parse(body) do
      %JsonApi{
        links: parse_links(parsed),
        data: parse_data(parsed)
      }
    end
  end

  @spec parse_links(%{}) :: %{}
  defp parse_links(%{"links" => links}) do
    links
  end
  defp parse_links(_) do
    %{}
  end

  defp parse_data(%{"data" => data} = parsed) when is_list(data) do
    data
    |> Enum.map(&(parse_data_item(&1, parsed)))
  end
  defp parse_data(%{"data" => data} = parsed) do
    %{parsed | "data" => [data]}
    |> parse_data
  end

  def parse_data_item(%{"type" => type, "id" => id, "attributes" => attributes} = item, parsed) do
    %JsonApi.Item{
      type: type,
      id: id,
      attributes: attributes,
      relationships: load_relationships(item["relationships"], parsed)
    }
  end

  defp load_relationships(nil, parsed) do
    %{}
  end
  defp load_relationships(%{} = relationships, parsed) do
    relationships
    |> map_values(&(load_single_relationship(&1, parsed)))
  end

  defp map_values(map, f) do
    map
    |> Enum.map(fn({key, value}) -> {key, (f).(value)} end)
    |> Enum.into(%{})
  end

  defp load_single_relationship(%{"data" => data}, parsed) when is_list(data) do
    data
    |> Enum.flat_map(&(match_included(&1, parsed)))
    |> (fn(item) -> parse_data(%{parsed | "data" => item}) end).()
  end
  defp load_single_relationship(%{"data" => data} = relationship, parsed) do
    data
    |> match_included(parsed)
    |> (fn(item) -> parse_data(%{parsed | "data" => item}) end).()
  end

  defp match_included(nil, _) do
    []
  end
  defp match_included(%{"type" => type, "id" => id}, %{"included" => included}) do
    included
    |> Enum.filter(&(&1["type"] == type && &1["id"] == id))
  end

end
