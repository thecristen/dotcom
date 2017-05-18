defmodule Site.GreenLine.Cache do
  @moduledoc """
  This supervised GenServer populates the GreenLine.DateAgent caches.
  By default, it will ensure an agent is running for every date from
  Util.service_date() until Schedules.Repo.end_of_rating().

  It then schedules a message to itself to update all these agents at
  about 7am ET the next morning.
  """

  use GenServer

  alias Site.GreenLine.{CacheSupervisor, DateAgent}

  # Client

  def start_link(opts \\ []) do
    start_date_fn = Keyword.get(opts, :start_date_fn, &Util.service_date/0)
    end_date_fn = Keyword.get(opts, :end_date_fn, &Schedules.Repo.end_of_rating/0)
    reset_fn = Keyword.get(opts, :reset_fn, &reset_cache/1)
    name = Keyword.get(opts, :name, :green_line_cache)

    GenServer.start_link(__MODULE__, {start_date_fn, end_date_fn, reset_fn}, name: name)
  end

  @doc """
  Retrieves the stops_on_routes information for a given date from the cache. If the
  Agent serving as the cache does not exist, this will start it up, which will fetch
  and populate the data.

  The registry is first queried in the client process to prevent bottlenecks. If no
  such agent is running, it will attempt to start the agent, but it must handle the
  case of a concurrent process also trying to query the agent and starting it up.
  """
  @spec stops_on_routes(0 | 1, Date.t | nil) :: GreenLine.stop_routes_pair
  def stops_on_routes(direction_id, date) do
    GenServer.call(:green_line_cache, {:stops_on_routes, direction_id, date})
  end

  @doc "Reset (requery the API) a given date's cache"
  @spec reset_cache(Date.t | nil) :: any
  def reset_cache(date) do
    case DateAgent.lookup(date) do
      nil -> CacheSupervisor.start_child(date)
      pid -> DateAgent.reset(pid, date)
    end
  end

  # Server

  def init({start_date_fn, end_date_fn, reset_fn}) do
    send self(), :populate_caches
    {:ok, {start_date_fn, end_date_fn, reset_fn}}
  end

  def handle_call({:stops_on_routes, direction_id, date}, _from, {start_date_fn, end_date_fn, _} = state) do
    if !date || (start_date_fn.() <= date && date <= end_date_fn.()) do
      agent_pid = case DateAgent.lookup(date) do
        nil ->
          case CacheSupervisor.start_child(date) do
            {:ok, pid} -> pid
            {:error, {:already_started, pid}} -> pid # race condition from concurrent req - no cover
          end
        pid -> pid
      end

      {:reply, DateAgent.stops_on_routes(agent_pid, direction_id), state}
    else
      {:reply, GreenLine.calculate_stops_on_routes(direction_id, date), state}
    end
  end

  def handle_info(:populate_caches, {start_date_fn, end_date_fn, reset_fn} = state) do
    previous_day = Timex.shift(start_date_fn.(), days: -1)

    if pid = DateAgent.lookup(previous_day) do
      DateAgent.stop(pid)
    end

    reset_fn.(nil)
    populate_cache(start_date_fn.(), end_date_fn.(), reset_fn)

    Process.send_after(
      self(),
      :populate_caches,
      next_update_after(Timex.now("America/New_York"))
    )

    {:noreply, state}
  end
  def handle_info(_, state) do
    {:noreply, state} # no cover
  end

  def next_update_after(now) do
    tomorrow_morning =
      now
      |> Timex.shift(days: 1)
      |> Timex.beginning_of_day
      |> Timex.shift(hours: 7)

    Timex.diff(tomorrow_morning, now, :milliseconds)
  end

  defp populate_cache(date, last_date, reset_fn) do
    if Timex.before?(date, Timex.shift(last_date, days: 1)) do
      reset_fn.(date)
      populate_cache(Timex.shift(date, days: 1), last_date, reset_fn)
    end
  end
end
