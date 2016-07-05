defmodule Routes.Group do
  @moduledoc """

  Groups a list of Route structures into a map based on their type: Commuter Rail, Bus, or Subway

  """
  alias Routes.Route

  @spec group([Route]) :: %{String: Route}
  def group(routes) do
    routes
    |> Enum.reverse
    |> Enum.filter_map(&filter/1, &filter_map/1)
    |> Enum.reduce(%{}, &reducer/2)
  end

  defp filter(%Route{type: 0, id: "Green-B"}), do: true
  defp filter(%Route{type: 0}), do: false
  defp filter(_), do: true

  defp filter_map(%Route{type: 0} = route) do
    %Route{route | name: "Green Line", id: "Green"}
  end
  defp filter_map(item) do
    item
  end

  defp reducer(route, acc) do
    acc_key = key(route)

    acc
    |> Dict.update(acc_key, [route], fn(value) -> [route|value] end)
  end

  defp key(%{type: 0}) do
    :subway
  end
  defp key(%{type: 1}) do
    :subway
  end
  defp key(%{type: 2}) do
    :commuter_rail
  end
  defp key(%{type: 3}) do
    :bus
  end
  defp key(%{type: _}) do
    :other
  end

end
