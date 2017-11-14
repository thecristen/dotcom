defmodule Site.GreenLine.CacheSupervisorTest do
  use ExUnit.Case

  import Site.GreenLine.CacheSupervisor

  test "CacheSupervisor is started along with registry" do
    assert {:error, {:already_started, _}} = start_link()
    assert {:error, {:already_started, _}} = Registry.start_link(:unique, :green_line_cache_registry)
  end

  test "can start a child and retrieve it" do
    date = Util.service_date
    pid = lookup(date)
    Site.GreenLine.DateAgent.stop(pid)
    assert lookup(date) == nil

    assert {:ok, pid} = start_child(date)
    assert pid == lookup(date)
  end
end
