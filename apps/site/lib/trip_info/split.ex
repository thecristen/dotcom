defmodule TripInfo.Split do
  @doc """

  Splits a list of times into smaller groups.

  * origin_ids is a list of starting locations. We want to show all of these,
    along with one stop afterwards.
  * destination_id is the last stop.  We want to display this, along with the stop before it.
  """
  @spec split(TripInfo.time_list, [String.t], String.t) :: [TripInfo.time_list]
  def split(times, origin_ids, destination_ids)
  def split([one, two, _, _, _ | _] = times, _origin_ids, _destination_id) do
    # if there are more than five items, split them up
    last_two = Enum.take(times, -2)
    [[one, two], last_two]
  end
  def split(times, _origin_ids, _destination_ids) do
    # not enough times, display them all
    [times]
  end
end
