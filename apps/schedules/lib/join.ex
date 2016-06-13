defmodule Join do
  @moduledoc """

  Given two lists of items and a function on those items, returns pairs of
  items where the function returns the same value for both items.  Currently,
  assumes that the function returns a unique value for an item in a given
  list.


  iex> Join.join([1, 2], [4, 5], fn i -> rem i, 2 end)
  [{2, 4}, {1, 5}]

  """

  def join(s, r, key_fn) when length(s) <= length(r) do
    s_map = s |> Enum.map(fn item ->
      {key_fn.(item), item} end) |> Enum.into(%{})

    r
    |> Stream.map(fn item -> {s_map[key_fn.(item)], item} end)
    |> Enum.filter(fn {s_item, _} -> s_item != nil end)
  end

  def join(s, r, key_fn) do
    # join them with the smaller one first, then flip the pairs
    r
    |> join(s, key_fn)
    |> Enum.map(fn {a, b} -> {b, a} end)
  end
end
