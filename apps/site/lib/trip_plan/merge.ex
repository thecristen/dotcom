defmodule Site.TripPlan.Merge do
  @moduledoc false

  @doc """
  Merges a list of accessible itineraries with unknown ones, preferring the
  accessible itineraries but including at least one from the unknown list.
  """
  def merge_itineraries(accessible, unknown) do
    merge(accessible, unknown, &TripPlan.Itinerary.same_itinerary?/2)
  end

  @doc """
  Merges two sets of lists, preferring items from the first list.

  We want the first one from each list, and then the next ones from the
  remaining lists.  Takes as argument for a function which returns true if
  they're equal.

  iex> merge([a: true, b: true, d: true], [a: false, b: false, c: false],
  ...> fn first, second -> elem(first, 0) == elem(second, 0) end)
  [a: true, b: true, c: false]

  iex> merge([d: true, e: true, f: true], [a: false, b: false, c: false],
  ...> fn first, second -> elem(first, 0) == elem(second, 0) end)
  [a: false, b: false, d: true]
  """
  @spec merge([a], [a], ((a, a) -> boolean)) :: [a]
  when a: term
  def merge(first, second, fun) do
    do_merge(first, second, fun, true, 3)
  end

  defp do_merge(_, _, _, _, remaining) when remaining <= 0 do
    []
  end
  defp do_merge(first, [], _fun, _, remaining) do
    Enum.take(first, remaining)
  end
  defp do_merge([], second, _fun, _, remaining) do
    Enum.take(second, remaining)
  end
  defp do_merge([f | _], _, _, true, 1) do
    # if there's only one remaining and we still need one from the first list, now is the time!
    [f]
  end
  defp do_merge([f | f_rest], [s | s_rest], fun, needs_first?, remaining) do
    # we have a trip from the first list, so we take both heads if they're equal, otherwise only the first
    if fun.(f, s) do
      [f | do_merge(f_rest, s_rest, fun, false, remaining - 1)]
    else
      # we take the first from s, and keep the needs_first? state
      [s | do_merge([f | f_rest], s_rest, fun, needs_first?, remaining - 1)]
    end
  end
end
