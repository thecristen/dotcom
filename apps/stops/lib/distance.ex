defmodule Stops.Distance do
  @moduledoc """

  Helper functions for working with distances between Stop.Position items.

  """
  alias Stops.Position
  import Stops.Position

  @doc "Sorts the items by their distance from position."
  @spec sort([Position.t], Position.t) :: [Position.t]
  def sort(items, position) do
    items
    |> Enum.sort_by(&distance_comp(position, &1))
  end

  @doc "Returns count items closest to position"
  @spec closest([Position.t], Position.t, non_neg_integer) :: [Position.t]
  def closest(items, position, count)
  def closest([], _, _), do: []
  def closest(_, _, 0), do: []
  def closest(items, position, count) do
    items
    |> Enum.sort_by(&distance_comp(position, &1))
    |> Enum.take(count)
  end

  @doc "Return a value to compare the distance between points.  Does not represent an actual distance."
  def distance_comp(first, second) do
    :math.pow(latitude(first) - latitude(second), 2) + :math.pow(longitude(first) - longitude(second), 2)
  end
end
