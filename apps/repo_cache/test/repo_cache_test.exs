defmodule RepoCacheTest.Repo do
  use RepoCache, ttl: :timer.seconds(1)

  def time(value, cache_opts \\ []) do
    cache(value, fn _ -> System.monotonic_time end, cache_opts)
  end

  def always(value) do
    cache(value, fn v -> v end)
  end
end

defmodule RepoCacheTest do
  use ExUnit.Case, async: true
  alias RepoCacheTest.Repo

  test "returns the cache result multiple times for the same key" do
    assert Repo.time(1) == Repo.time(1)
  end

  test "returns different values for different keys" do
    assert Repo.time(1) != Repo.time(2)
  end

  test "returns different values for the same key on different methods" do
    assert Repo.time(1) != Repo.always(1)
  end
end
