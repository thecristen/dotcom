defmodule SystemMetricsTest do
  use ExUnit.Case

  describe "SystemMetrics" do
    test "start/2" do
      {:error, {status, pid}} = SystemMetrics.start(nil, nil)
      assert status == :already_started
      assert Process.alive?(pid)
    end
  end
end
