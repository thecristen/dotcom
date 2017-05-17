defmodule Site.GreenLine.CacheWarmerTest do
  use ExUnit.Case, async: true

  alias Site.GreenLine.CacheWarmer

  test "it calls the reset function for every date in the range" do
    test_pid = self()
    start_date_fn = fn -> ~D[1985-03-31] end
    end_date_fn = fn -> ~D[1985-04-03] end
    reset_fn = fn date -> send(test_pid, {:done, date}) end

    CacheWarmer.start_link(start_date_fn: start_date_fn, end_date_fn: end_date_fn, reset_fn: reset_fn)

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

  test "next_update_after/1 calculates proper wait time" do
    start =
      Timex.now("America/New_York")
      |> Timex.beginning_of_day
      |> Timex.shift(hours: 20)

    # 8pm -> 7am = 11 hrs = 39,600,000 ms

    assert CacheWarmer.next_update_after(start) == 39_600_000
  end
end
