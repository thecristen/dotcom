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
      needed_accessible: 2, total: 4)
  end

  @doc """
  Merges two sets of lists, requiring items from the accessible list but
  preferring items from the unknown list. Takes as an argument a function
  which returns true if two items from the lists are equal.

  The reason for the preference is that we assume that a better itinerary
  would be in the unknown list as well as the accessible one. If it only
  appears in the accessible list, it's worse than the itineraries in the
  unknown list.

  ## Examples

  We'll return values from the accessible list as long as they're equal to items
  in the unknown list (the function is comparing the atoms):

      iex> merge([a: true, b: true, d: true], [a: false, b: false, c: false],
      ...> fn {accessible, _}, {unknown, _} -> accessible == unknown end)
      [a: true, b: true, c: false]

  If the top items are not equal, we'll still return at least one item from
  the accessible list:

      iex> merge([d: true, e: true, f: true], [a: false, b: false, c: false],
      ...> fn {a, _}, {u, _} -> a == u end)
      [a: false, b: false, d: true]

  If given a different total number of items, or items needed from the accessible
  list, we'll use those values instead of the defaults of 1 item from the
  accessible list and 3 total:

      iex> merge([d: true, e: true, f: true], [a: false, b: false, c: false],
      ...> fn {a, _}, {u, _} -> a == u end,
      ...> needed_accessible: 2, total: 4)
      [a: false, b: false, d: true, e: true]
  """
  @spec merge([a], [a], ((a, a) -> boolean), Keyword.t) :: [a]
  when a: term
  def merge(accessible, unknown, fun, opts \\ []) do
    needed_accessible = Keyword.get(opts, :needed_accessible, 1)
    total = Keyword.get(opts, :total, 3)
    do_merge(accessible, unknown, fun, needed_accessible, total)
  end

  defp do_merge(_, _, _, _, total) when total <= 0 do
    []
  end
  defp do_merge(accessible, [], _fun, _, total) do
    Enum.take(accessible, total)
  end
  defp do_merge([], unknown, _fun, _, total) do
    Enum.take(unknown, total)
  end
  defp do_merge(accessible, _, _, total, total) do
    # if we need all the rest from the accessible list, do that
    Enum.take(accessible, total)
  end
  defp do_merge([a | a_rest] = a_all, [u | u_rest], fun, needed_accessible, total) do
    # we have a trip from the accessible list, so we take both heads if they're equal, otherwise only the accessible
    if fun.(a, u) do
      [a | do_merge(a_rest, u_rest, fun, needed_accessible - 1, total - 1)]
    else
      # we take the accessible from s, and still need the same from the accessible list
      [u | do_merge(a_all, u_rest, fun, needed_accessible, total - 1)]
    end
  end
end
