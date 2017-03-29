defmodule SystemMetrics.MonitorTest do
  @meter Application.get_env(:system_metrics, :meter)
  use ExUnit.Case

  describe "SystemMetrics.Monitor" do

    setup do
      @meter.clear()
    end

    test "start_link/0"  do
      {status, pid} = SystemMetrics.Monitor.start_link()
      assert status == :ok
      assert Process.alive?(pid)
    end

    test "init/1" do
      {status, state} = SystemMetrics.Monitor.init([])
      assert status == :ok
      assert state == []
    end

    test "handle_info/2" do
      # start agent process
      @meter.start_link()

      # call handle info directly
      expected = {:noreply, nil}
      actual = SystemMetrics.Monitor.handle_info(:work, nil)
      assert expected == actual

      # get the data from elixometer
      collected_data = @meter.dump()

      # make sure we have all the pertinent keys, and values are more than 0
      for {{:gauge, key}, value} <- collected_data do
        assert Enum.member?(["cpu_load", "memory_available", "memory_used"], key)
        assert value > 0
      end

    end
  end
end
