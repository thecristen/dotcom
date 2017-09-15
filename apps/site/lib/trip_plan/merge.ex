defmodule Site.TripPlan.Merge do
  @moduledoc false
  @doc """
  Merges two sets of itineraries: generally one accessible and one unknown.

  We want the first one from each list, and then the lowest one from the
  remaining lists.  Takes as argument for a function to order by.

  iex> merge([1, 2, 3], [4, 5, 6], fn x -> x end)
  [1, 4, 2]
  """
  @spec merge([a], [a], ((a) -> any)) :: [a]
  when a: term
  def merge(first, second, fun)
  def merge(first, [], _fun) do
    Enum.take(first, 3)
  end
  def merge([], second, _fun) do
    Enum.take(second, 3)
  end
  def merge([f | f_rest], [s | s_rest], fun) do
    combined_rest = Enum.concat(f_rest, s_rest)
    f_val = fun.(f)
    s_val = fun.(s)
    cond do
      f_val == s_val ->
        [f | merge_rest(combined_rest, fun, 2)]
      f_val < s_val ->
        [f, s | merge_rest(combined_rest, fun, 1)]
      true ->
        [s, f | merge_rest(combined_rest, fun, 1)]
    end
  end

  defp merge_rest(rest, fun, number_to_take) do
    rest
    |> Enum.sort_by(fun)
    |> Enum.take(number_to_take)
  end
end
