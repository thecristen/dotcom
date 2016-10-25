defmodule AndJoin do
  @doc """

  Joins a list of strings with commas, with an "and" before the last item.

  """
  @spec and_join([String.t]) :: iolist
  def and_join([]), do: ""
  def and_join([single]), do: single
  def and_join([one, two]) do
    [one, " and ", two]
  end
  def and_join([one, two, three]) do
    [one, ", ", two, ", and ", three]
  end
  def and_join([first | rest]) do
    [
      first,
      ", ",
      and_join(rest)
    ]
  end
end
