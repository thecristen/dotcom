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
  def split([second_to_last, last], _starting_stop_ids) do
    # we're always keeping the last two
    [[second_to_last, last]]
  end
  def split([last], _starting_stop_ids) do
    [[last]]
  end
  def split([], _starting_stop_ids) do
    # with no times, return no sections
    []
  end
  def split([first | rest], starting_stop_ids) do
    # split the rest of the list into two: the first part being everything up
    # to the next origin, the second part being the rest.
    {until_next_origin, next_origin_and_rest} = Enum.split_while(rest, & ! &1.stop.id in starting_stop_ids)

    # split the next origin and everything else into sections
    case split(next_origin_and_rest, starting_stop_ids) do
      [] ->
        # the last section is a special case
        do_handle_end(first, until_next_origin)
      [next_section | other_sections] ->
        case until_next_origin do
          [] ->
            # next origin starts with the next item, so prepend first to the next section
            [[first | next_section] | other_sections]
          [one_between] ->
            # one time between us and the next section, so prepend both to the next section
            [[first, one_between | next_section] | other_sections]
          [next | _skipped] ->
            # there's at least one item to so, only hang onto the next time
            [[first, next], next_section | other_sections]
        end
    end
  end

  defp do_handle_end(first, [one, last]) do
    # origin is separated from the destination by one, so group them togehter
    [[first, one, last]]
  end
  defp do_handle_end(first, [one, two, last]) do
    # origin is separated from the destination by two, so group them together
    [[first, one, two, last]]
  end
  defp do_handle_end(first, [in_previous_section, _, _, _ |_] = rest) do
    # origin is separated from destination by more than two, so the first
    # remaining one is part of the origin section.  The destination section
    # is the last two items.
    [[first, in_previous_section], Enum.take(rest, -2)]
  end
end
