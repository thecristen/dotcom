defmodule Site.Plugs.ScheduleV2.DirectionNames do
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{schedules: schedules, all_stops: all_stops}} = conn, []) do
    conn
    |> assign(:from, from(schedules, all_stops))
  end

  @doc "Given a list of schedules, return where those schedules start (best-guess)"
  def from([], _) do
    %Schedules.Stop{id: nil}
  end
  def from([{%{stop: %{id: stop_id}}, _} | _], all_stops) do
    # with a pair, we have the origin already as the first in the pair
    stop_id
    |> find_stop(all_stops)
  end
  def from(all_schedules, all_stops) do
    # otherwise, find all the stop IDs and pick the most frequent
    all_schedules
    |> Enum.map(fn schedule -> schedule.stop.id end)
    |> Util.most_frequent_value
    |> find_stop(all_stops)
  end

  defp find_stop(stop_id, all_stops) do
    case all_stops
    |> Enum.find(&(&1.id == stop_id)) do
      nil -> %Schedules.Stop{id: nil}
      stop -> stop
    end
  end
end
