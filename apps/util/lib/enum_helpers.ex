defmodule Util.EnumHelpers do
  @doc """

  Takes an Enumerable and returns a list with the first and last items tagged
  with a boolean true.

  iex> with_first_last([1, 2, 3])
  [{1, true}, {2, false}, {3, true}]
  """
  @spec with_first_last(Enum.t) :: [{any, boolean}]
  def with_first_last([]) do
    []
  end
  def with_first_last([only]) do
    [{only, true}]
  end
  def with_first_last([first | rest]) do
    [{first, true} | do_with_first_last(rest, [])]
  end

  defp do_with_first_last([last], acc) do
    Enum.reverse([{last, true} | acc])
  end
  defp do_with_first_last([item | rest], acc) do
    do_with_first_last(rest, [{item, false} | acc])
  end

  @doc """
  Takes a list of n elements of the form [0, 1, 2 ... n - 3, n - 2, n - 1]
  and transforming to a 3-tuple of the form {[0, 1], [2 ... n - 3], [n - 2, n - 1]}
  """
  def pop_off_front_and_back(enum, number) do
    pop_off_front_and_back(enum, number, number)
  end
  def pop_off_front_and_back(enum, front, back) do
    enum
    |> Enum.split(front)
    |> (fn {f, l} ->
          {m, ll} = Enum.split(l, -1 * back)
          {f, m, ll}
        end).()
  end
end
