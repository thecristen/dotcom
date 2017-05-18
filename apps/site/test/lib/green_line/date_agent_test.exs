defmodule Site.GreenLine.DateAgentTest do
  use ExUnit.Case

  import Site.GreenLine.DateAgent

  test "Can stop an agent" do
    {:ok, pid} = start_link(~D[2016-01-01], :green_line_date_agent_test_stop)
    :ok = stop(pid)
    assert !Process.alive?(pid)
  end

  test "Starting an agent calls its calculate_state function, and the values can be retrieved" do
    date = ~D[2016-01-02]
    {:ok, pid} = start_link(date, :green_line_date_agent_test_state_calc, fn _ -> {1, 2} end)
    assert stops_on_routes(pid, 0) == 1
    assert stops_on_routes(pid, 1) == 2

    reset(pid, date, fn _ -> {3, 4} end)
    assert stops_on_routes(pid, 0) == 3
    assert stops_on_routes(pid, 1) == 4
  end
end
