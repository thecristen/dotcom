defmodule AndJoin do
  @doc """

  Joins a list of strings with commas, with an "and" before the last item.

  """
  @spec join([String.t]) :: iolist
  def join([]), do: ""
  def join([single]), do: single
  def join([one, two]) do
    [one, " and ", two]
  end
  def join([one, two, three]) do
    [one, ", ", two, ", and ", three]
  end
  def join([first | rest]) do
    [
      first,
      ", ",
      join(rest)
    ]
  end
end
