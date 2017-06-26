defmodule Routes.Group do
  @moduledoc """

  Groups a list of Route structures into a keyword dict based on their type: Commuter Rail, Bus, or Subway

  """
  alias Routes.Route

  @type t :: {Routes.Route.route_type, Routes.Route.t}

  @spec group([Route.t]) :: [Routes.Group.t]
  def group(routes) do
    routes
    |> combine_green_line_into_single_route
    |> group_items_by_route_type
    |> Enum.sort_by(&sorter/1)
  end

  @spec combine_green_line_into_single_route([Route.t]) :: [Route.t]
  defp combine_green_line_into_single_route(routes) do
    routes
    |> Enum.uniq_by(fn
      %{id: "Green" <> _} -> "Green"
      %{"id": id} -> id
    end)
    |> Enum.map(&set_green_line_name/1)
  end

  defp set_green_line_name(%Route{type: 0, id: "Green" <> _} = route) do
    %{route | name: "Green Line", id: "Green"}
  end
  defp set_green_line_name(item) do
    item
  end

  defp group_items_by_route_type(routes) do
    Enum.group_by(routes, &Route.type_atom(&1))
  end

  def sorter({:subway, _}), do: 0
  def sorter({:commuter_rail, _}), do: 1
  def sorter({:bus, _}), do: 2
  def sorter({:ferry, _}), do: 3
end
