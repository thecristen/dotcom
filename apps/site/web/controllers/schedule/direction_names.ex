defmodule Site.ScheduleController.DirectionNames do
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{schedules: schedules, all_stops: all_stops}} = conn, []) do
    conn
    |> assign(:from, from(schedules, all_stops))
    |> assign(:to, to(schedules))
  end

  @doc "Given a list of schedules, return where those schedules start (best-guess)"
  def from([], _) do
    nil
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

  @doc "Given a list of schedules, return a list of where those schedules stop"
  def to([]) do
    nil
  end
  def to([{_, _} | _] = all_schedules) do
    # with pairs, they should share a trip so we can pull out one of them
    all_schedules
    |> Enum.map(fn {departure, _} -> departure end)
    |> to
  end
  def to(all_schedules) do
    all_schedules
    |> Enum.map(fn schedule -> schedule.trip.headsign end)
    |> Enum.uniq
  end

  defp find_stop(stop_id, all_stops) do
    all_stops
    |> Enum.find(&(&1.id == stop_id))
  end
end
