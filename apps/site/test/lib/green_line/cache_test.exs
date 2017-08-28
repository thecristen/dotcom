defmodule Site.GreenLine.CacheTest do
  use ExUnit.Case

  import Site.GreenLine.Cache

  test "it calls the reset function for every date in the range" do
    test_pid = self()
    start_date_fn = fn -> ~D[1985-03-31] end
    end_date_fn = fn -> ~D[1985-04-03] end
    reset_fn = fn date -> send(test_pid, {:done, date}) end

    start_link(start_date_fn: start_date_fn, end_date_fn: end_date_fn, reset_fn: reset_fn, name: :test1)

    msgs = receive_dates([nil, ~D[1985-03-31], ~D[1985-04-01], ~D[1985-04-02], ~D[1985-04-03], ~D[1985-04-04]])

    assert msgs == [:ok, :ok, :ok, :ok, :ok, :nothing]
  end

  test "it does not run forever if the end_date_fn returns nil" do
    test_pid = self()
    start_date_fn = fn -> ~D[1985-03-31] end
    end_date_fn = fn -> nil end
    reset_fn = fn date -> send(test_pid, {:done, date}) end

    start_link(start_date_fn: start_date_fn, end_date_fn: end_date_fn, reset_fn: reset_fn, name: :test1)

    msgs = receive_dates([nil, ~D[1985-03-31], ~D[1985-04-01]])

    assert msgs == [:ok, :ok, :nothing]
  end

  test "next_update_after/1 calculates proper wait time" do
    start =
      Timex.now("America/New_York")
      |> Timex.beginning_of_day
      |> Timex.shift(hours: 20)

    # 8pm -> 7am = 11 hrs = 39,600,000 ms

    assert next_update_after(start) == 39_600_000
  end

  test "it stops the previous day's agent" do
    yesterday = ~D[1987-03-31]
    Site.GreenLine.CacheSupervisor.start_child(yesterday)

    test_pid = self()
    start_date_fn = fn -> ~D[1987-04-01] end
    end_date_fn = fn -> ~D[1987-04-02] end
    reset_fn = fn date -> send(test_pid, {:done, date}) end

    start_link(start_date_fn: start_date_fn, end_date_fn: end_date_fn, reset_fn: reset_fn, name: :test3)

    msgs = receive_dates([nil, ~D[1987-04-01], ~D[1987-04-02]])
    assert msgs == [:ok, :ok, :ok]
    assert nil == Site.GreenLine.CacheSupervisor.lookup(yesterday)
  end

  test "reset_cache/1 sends a message if it fails" do
    invalid_date = ~D[1900-01-01]
    reset_cache(invalid_date, 50)

    msg = receive do
      {:reset_again, ^invalid_date} -> :ok
    after
      100 -> :no_msg
    end

    assert msg == :ok
  end

  defp receive_dates(dates) do
    for date <- dates do
      receive do
        {:done, ^date} -> :ok
      after
        100 -> :nothing
      end
    end
  end
end
