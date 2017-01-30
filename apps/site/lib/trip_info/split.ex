defmodule TripInfo.Split do
  @doc """

  Splits a list of times into smaller groups.

  * starting_stop_ids is a list of starting stop_ids. We want to show all of these,
    along with at least one stop afterwards.

  The destination is the last stop.  We want to keep that, along with the
  second-to-last stop as well.
  """
  @spec split(TripInfo.time_list, [String.t]) :: [TripInfo.time_list]
  def split(times, starting_stop_ids)
  def split([], _starting_stop_ids) do
    # with no times, return no sections
    []
  end
  def split([first | rest], starting_stop_ids) do
    # split the rest of the list into two: the first part being everything up
    # to the next origin, the second part being the rest.
    {until_next_start, next_start_and_rest} = Enum.split_while(rest, & ! PredictedSchedule.stop_id(&1) in starting_stop_ids)

    do_split([first | until_next_start], next_start_and_rest)
  end

  defp do_split([first, second, _, _, _ | _], [next_first, next_second, _, _, _, _before_destination, _destination | _] = last_section) do
    # there are enough stops in both the first and second groups to break into three sections
    [
      [first, second],
      [next_first, next_second],
      Enum.take(last_section, -2)
    ]
  end
  defp do_split([first, second, _, _, _ | _], [_ | _] = last_section) do
    # the first section is big enough to split, but the second is not
    [
      [first, second],
      last_section
    ]
  end
  defp do_split([first, second, _, _, _, _before_destination, _destination | _] = first_section, []) do
    # there's no middle ID (second section is empty), so break into two sections
    [
      [first, second],
      Enum.take(first_section, -2)
    ]
  end
  defp do_split(first_section, [next_first, next_second, _, _, _, _before_destination, _destination | _] = last_section) do
    # the second section is big enough to split, but the first is not
    [
      Enum.concat(first_section, [next_first, next_second]),
      Enum.take(last_section, -2)
    ]
  end
  defp do_split(first_section, last_section) do
    # both are small, so concat them
    [
      Enum.concat(first_section, last_section)
    ]
  end
end
