defmodule Site.GreenLine.DateAgentTest do
  use ExUnit.Case

  import Site.GreenLine.DateAgent

  test "Can register a date agent for a given date, and then stop it" do
    date = ~D[2016-01-01]
    {:ok, pid} = start_link(date)
    assert pid == lookup(date)

    :ok = stop(pid)
    :timer.sleep(1000)
    assert nil == lookup(date)
  end

  test "Starting an agent calls its calculate_state function, and the values can be retrieved" do
    date = ~D[2016-01-02]
    {:ok, pid} = start_link(date, fn _ -> {1, 2} end)
    assert stops_on_routes(pid, 0) == 1
    assert stops_on_routes(pid, 1) == 2

    reset(pid, date, fn _ -> {3, 4} end)
    assert stops_on_routes(pid, 0) == 3
    assert stops_on_routes(pid, 1) == 4
  end
end
