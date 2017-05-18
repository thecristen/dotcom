defmodule Site.GreenLine.CacheTest do
  use ExUnit.Case

  import Site.GreenLine.Cache

  test "stops_on_routes/2 works on first call and when cached" do
    date = ~D[2015-01-01]
    assert {{:error, [%JsonApi.Error{}]}, %{}} = stops_on_routes(0, date)
    assert {{:error, [%JsonApi.Error{}]}, %{}} = stops_on_routes(0, date)
  end

  test "reset_cache/1 works when agent exists or it doesn't" do
    date = ~D[2015-01-02]
    assert {:ok, _pid} = reset_cache(date)
    assert :ok = reset_cache(date)
  end

  test "it calls the reset function for every date in the range" do
    test_pid = self()
    start_date_fn = fn -> ~D[1985-03-31] end
    end_date_fn = fn -> ~D[1985-04-03] end
    reset_fn = fn date -> send(test_pid, {:done, date}) end

    start_link(start_date_fn: start_date_fn, end_date_fn: end_date_fn, reset_fn: reset_fn, name: :test1)

    msgs = receive_dates([nil, ~D[1985-03-31], ~D[1985-04-01], ~D[1985-04-02], ~D[1985-04-03], ~D[1985-04-04]])

    assert msgs == [:ok, :ok, :ok, :ok, :ok, :nothing]
  end

  test "next_update_after/1 calculates proper wait time" do
    start =
      Timex.now("America/New_York")
      |> Timex.beginning_of_day
      |> Timex.shift(hours: 20)

    # 8pm -> 7am = 11 hrs = 39,600,000 ms

    assert next_update_after(start) == 39_600_000
  end

  test "it doesn't start up a process for a date outside the range" do
    start_date_fn = fn -> ~D[1986-03-31] end
    end_date_fn = fn -> ~D[1986-04-01] end
    reset_fn = fn _ -> :ok end

    start_link(start_date_fn: start_date_fn, end_date_fn: end_date_fn, reset_fn: reset_fn, name: :test2)

    invalid_date = ~D[1986-04-02]

    assert {{:error, [%JsonApi.Error{}]}, %{}} = stops_on_routes(0, invalid_date)
    assert nil == Site.GreenLine.DateAgent.lookup(invalid_date)
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
    assert nil == Site.GreenLine.DateAgent.lookup(yesterday)
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
