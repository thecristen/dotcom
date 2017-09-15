defmodule Site.TripPlan.Merge do
  @moduledoc false

  @doc """
  Merges a list of accessible itineraries with unknown ones, preferring the
  unknown itineraries but including at least two from each list.

  See `merge/4` for more documentation about how we pull from the two lists.
  """
  @spec merge_itineraries(itinerary_list, itinerary_list) :: itinerary_list
  when itinerary_list: [TripPlan.Itinerary.t]
  def merge_itineraries(accessible, unknown) do
    merge(accessible, unknown, &TripPlan.Itinerary.same_itinerary?/2,
      needed_first: 2, total: 4)
  end

  @doc """
  Merges two sets of lists, requiring items from the first list but
  preferring items from the second list. Takes as an argument a function
  which returns true if two items from the lists are equal.

  ## Examples

  We'll return values from the first list as long as they're equal to items
  in the second list (the function is comparing the atoms):

      iex> merge([a: true, b: true, d: true], [a: false, b: false, c: false],
      ...> fn {first, _}, {second, _} -> first == second end)
      [a: true, b: true, c: false]

  If the top items are not equal, we'll still return at least one item from
  the first list:

      iex> merge([d: true, e: true, f: true], [a: false, b: false, c: false],
      ...> fn {f, _}, {s, _} -> f == s end)
      [a: false, b: false, d: true]

  If given a different total number of items, or items needed from the first
  list, we'll use those values instead of the defaults of 1 item from the
  first list and 3 total:

      iex> merge([d: true, e: true, f: true], [a: false, b: false, c: false],
      ...> fn {f, _}, {s, _} -> f == s end,
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
