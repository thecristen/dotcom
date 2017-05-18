defmodule Site.GreenLine.DateAgent do
  @moduledoc """
  This is a supervised agent storing the cached results of a function for a given
  date.
  """

  import GreenLine, only: [calculate_stops_on_routes: 2]

  def stops_on_routes(pid, direction_id) do
    Agent.get(pid, fn state -> elem(state, direction_id) end)
  end

  def reset(pid, date, calculate_state_fn \\ &calculate_state/1) do
    Agent.update(pid, fn _ -> calculate_state_fn.(date) end)
  end

  def start_link(date, name, calculate_state_fn \\ &calculate_state/1) do
    Agent.start_link(fn -> calculate_state_fn.(date) end, name: name)
  end

  def stop(pid) do
    Agent.stop(pid)
  end

  defp calculate_state(date) do
    {calculate_stops_on_routes(0, date), calculate_stops_on_routes(1, date)}
  end
end
