defmodule Site.GreenLine.CacheWarmerTest do
  use ExUnit.Case, async: true

  alias Site.GreenLine.CacheWarmer

  test "it calls the reset function for every date in the range" do
    test_pid = self()
    reset_fn = fn date -> send(test_pid, {:done, date}) end

    CacheWarmer.start_link(start_date: ~D[1985-03-31], end_date: ~D[1985-04-03], reset_fn: reset_fn)

    msgs = for date <- [nil, ~D[1985-03-31], ~D[1985-04-01], ~D[1985-04-02], ~D[1985-04-03]] do
      receive do
        {:done, ^date} -> :ok
      end
    end

    assert msgs == [:ok, :ok, :ok, :ok, :ok]

    next_date = receive do
      {:done, _} -> :ok
    after
      0 -> :nothing
    end

    assert next_date == :nothing
  end
end
