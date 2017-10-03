defmodule RepoCacheTest.Repo do
  use RepoCache, ttl: :timer.seconds(1)

  def time(value) do
    cache(value, fn _ -> System.monotonic_time end)
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

  setup_all do
    {:ok, _} = Repo.start_link
    :ok
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

  test "does not cache errors" do
    {:ok, pid} = Agent.start_link fn -> {:error, :value} end
    assert {:error, :value} == Repo.agent_state(pid)
    Agent.update pid, fn _ -> :real end
    assert :real == Repo.agent_state(pid)
  end

  test "can clear the cache with clear_cache" do
    {:ok, pid} = Agent.start_link fn -> :value end
    assert :value == Repo.agent_state(pid)
    Agent.update pid, fn _ -> :real end
    assert :value == Repo.agent_state(pid)
    Repo.clear_cache
    assert :real == Repo.agent_state(pid)
  end

  describe "child_spec/1" do
    test "returns a child_spec map" do
      assert %{
        id: _,
        start: {_, _, _},
        type: _,
        restart: _,
        shutdown: _} = Repo.child_spec([])
    end
  end
end
