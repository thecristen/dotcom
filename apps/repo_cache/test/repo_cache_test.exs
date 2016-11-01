defmodule RepoCacheTest.Repo do
  use RepoCache, ttl: :timer.seconds(1)

  def time(value, cache_opts \\ []) do
    cache(value, fn _ -> System.monotonic_time end, cache_opts)
  end

  def always(value) do
    cache(value, fn v -> v end)
  end

  def agent_state(pid) do
    cache(pid, fn pid ->
      Agent.get(pid, fn state -> state end)
    end)
  end
end

defmodule RepoCacheTest do
  use ExUnit.Case, async: true
  alias RepoCacheTest.Repo

  defp purge_cache do
    # We send a bunch of :check_purge messages to force the ConCache.Owner
    # process to expire values.  Normally, we'd have to wait at least a
    # second, possibly 2, to have items expire automatically.
    pid = Process.whereis(:repo_cache_cache)
    Enum.each(0..2, fn _ ->
      send pid, :check_purge
    end)
    wait_for_empty_queue(pid)
  end

  defp wait_for_empty_queue(pid) do
    case Process.info(pid)[:message_queue_len] do
      0 -> :ok
      _ -> wait_for_empty_queue(pid)
    end
  end


  test "returns the cache result multiple times for the same key" do
    first = Repo.time(1)
    second = Repo.time(1)
    assert first == second
  end

  test "returns different values for different keys" do
    assert Repo.time(1) != Repo.time(2)
  end

  test "returns different values for the same key on different methods" do
    assert Repo.time(1) != Repo.always(1)
  end

  test "nil values aren't cached" do
    # We create an agent with a nil value, then change it to a different
    # value to assert that the cache picked up the new value
    {:ok, pid} = Agent.start_link(fn -> nil end)
    assert Repo.agent_state(pid) == nil
    Agent.update(pid, fn nil -> :value end)
    purge_cache
    assert Repo.agent_state(pid) == :value
  end

  test "empty lists aren't cached" do
    # We create an agent with a empty list value, then change it to a
    # different value to assert that the cache picked up the new value
    {:ok, pid} = Agent.start_link(fn -> [] end)
    assert Repo.agent_state(pid) == []
    Agent.update(pid, fn [] -> [1] end)
    purge_cache
    assert Repo.agent_state(pid) == [1]
  end
end
