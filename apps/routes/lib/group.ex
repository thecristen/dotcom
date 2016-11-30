defmodule Routes.Group do
  @moduledoc """

  Groups a list of Route structures into a keyword dict based on their type: Commuter Rail, Bus, or Subway

  """
  alias Routes.Route

  @type t :: {Routes.Route.route_type, Routes.Route.t}

  @spec group([Route.t]) :: [Routes.Group.t]
  def group(routes) do
    routes
    |> Enum.reverse
    |> Enum.filter_map(&filter/1, &filter_map/1)
    |> Enum.reduce([], &reducer/2)
    |> Enum.sort_by(&sorter/1)
  end

  defp filter(%Route{type: 0, id: "Green-B"}), do: true
  defp filter(%Route{type: 0, id: "Green" <> _}), do: false
  defp filter(_), do: true

  defp filter_map(%Route{type: 0, id: "Green" <> _} = route) do
    %{route | name: "Green Line", id: "Green"}
  end
  defp filter_map(item) do
    item
  end

  defp reducer(route, acc) do
    acc
    |> Dict.update(Route.type_atom(route), [route], fn(value) -> [route|value] end)
  end

  def sorter({:subway, _}), do: 0
  def sorter({:commuter_rail, _}), do: 1
  def sorter({:bus, _}), do: 2
  def sorter({:ferry, _}), do: 3
end
