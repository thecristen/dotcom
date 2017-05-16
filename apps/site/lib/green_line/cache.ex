defmodule Site.GreenLine.Cache do
  @moduledoc "The main interface to the cache of the GreenLine stops_on_routes information. "

  alias Site.GreenLine.{CacheSupervisor, DateAgent}

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
    agent_pid = case DateAgent.lookup(date) do
      nil ->
        case CacheSupervisor.start_child(date) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
      pid -> pid
    end

    DateAgent.stops_on_routes(agent_pid, direction_id)
  end

  @doc "Reset (requery the API) a given date's cache"
  @spec reset_cache(Date.t | nil) :: any
  def reset_cache(date) do
    case DateAgent.lookup(date) do
      nil -> CacheSupervisor.start_child(date)
      pid -> DateAgent.reset(pid, date)
    end
  end
end
