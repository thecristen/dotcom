defmodule TimeGroup do
  alias Schedules.Schedule

  @doc """
  Given a list of schedules, returns those schedules grouped by the hour of day.

  Returns a keyword list rather than a map so that the times appear in order.

  Precondition: the schedules are already sorted by time.
  """
  @spec by_hour([%Schedule{}]) :: [{non_neg_integer, [%Schedule{}]}]
  def by_hour([]) do
    []
  end
  def by_hour(schedules) do
    schedules
    |> Enum.reduce([], &reduce_by_hour/2)
    |> reverse_first_group
    |> Enum.reverse
  end

  @doc """
  Given a list of schedules, return the frequency of service in minutes.
  Returns either a min/max pair if there's a variation, or a single integer.
  """
  @spec frequency([%Schedule{}]) :: {non_neg_integer, non_neg_integer} | non_neg_integer
  def frequency([_,_|_] = schedules) do
    {min, max} = schedules
    |> Enum.zip(Enum.drop(schedules, 1))
    |> Enum.map(fn {x, y} -> Timex.diff(x.time, y.time, :minutes) end)
    |> Enum.min_max

    case {min, max} do
      {value, value} -> value
      _ -> {min, max}
    end
  end
  def frequency(_) do
    nil
  end

  defp reduce_by_hour(schedule, []) do
    [{schedule.time.hour, [schedule]}]
  end
  defp reduce_by_hour(schedule, [{hour, grouped}|rest]) do
    if hour == schedule.time.hour do
      head = {hour, [schedule|grouped]}
      [head|rest]
    else
      head = {schedule.time.hour, [schedule]}
      previous_head = {hour, Enum.reverse(grouped)}
      [head,previous_head|rest]
    end
  end

  defp reverse_first_group([{hour, grouped}|rest]) do
    head = {hour, Enum.reverse(grouped)}
    [head|rest]
  end
end
