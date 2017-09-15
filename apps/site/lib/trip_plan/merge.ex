defmodule Site.TripPlan.Merge do
  @moduledoc false

  @doc """
  Merges a list of accessible itineraries with unknown ones, preferring the
  accessible itineraries but including at least one from the unknown list.
  """
  def merge_itineraries(accessible, unknown) do
    merge(accessible, unknown, &TripPlan.Itinerary.same_itinerary?/2, needed_first: 2, total: 4)
  end

  @doc """
  Merges two sets of lists, preferring items from the first list.

  We want the first one from each list, and then the next ones from the
  remaining lists.  Takes as argument for a function which returns true if
  they're equal.

  iex> merge([a: true, b: true, d: true], [a: false, b: false, c: false],
  ...> fn first, second -> elem(first, 0) == elem(second, 0) end)
  [a: true, b: true, c: false]

  iex> merge([a: true, b: true, c: true], [a: false, b: false, c: false],
  ...> fn first, second -> elem(first, 0) == elem(second, 0) end, total: 4)
  [a: true, b: true, c: true]

  iex> merge([d: true, e: true, f: true], [a: false, b: false, c: false],
  ...> fn first, second -> elem(first, 0) == elem(second, 0) end)
  [a: false, b: false, d: true]

  iex> merge([d: true, e: true, f: true], [a: false, b: false, c: false],
  ...> fn first, second -> elem(first, 0) == elem(second, 0) end,
  ...> needed_first: 2, total: 4)
  [a: false, b: false, d: true, e: true]
  """
  @spec merge([a], [a], ((a, a) -> boolean), Keyword.t) :: [a]
  when a: term
  def merge(first, second, fun, opts \\ []) do
    needed_first = Keyword.get(opts, :needed_first, 1)
    total = Keyword.get(opts, :total, 3)
    do_merge(first, second, fun, needed_first, total)
  end

  defp do_merge(_, _, _, _, total) when total <= 0 do
    []
  end
  defp do_merge(first, [], _fun, _, total) do
    Enum.take(first, total)
  end
  defp do_merge([], second, _fun, _, total) do
    Enum.take(second, total)
  end
  defp do_merge(first, _, _, total, total) do
    # if we need all the rest from the first list, do that
    Enum.take(first, total)
  end
  defp do_merge([f | f_rest] = f_all, [s | s_rest], fun, needed_first, total) do
    # we have a trip from the first list, so we take both heads if they're equal, otherwise only the first
    if fun.(f, s) do
      [f | do_merge(f_rest, s_rest, fun, needed_first - 1, total - 1)]
    else
      # we take the first from s, and still need the same from the first list
      [s | do_merge(f_all, s_rest, fun, needed_first, total - 1)]
    end
  end
end
