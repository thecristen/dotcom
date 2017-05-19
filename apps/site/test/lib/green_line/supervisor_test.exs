defmodule Site.GreenLine.CacheSupervisorTest do
  use ExUnit.Case

  import Site.GreenLine.CacheSupervisor

  test "CacheSupervisor is started along with registry" do
    assert {:error, {:already_started, _}} = start_link()
    assert {:error, {:already_started, _}} = Registry.start_link(:unique, :green_line_cache_registry)
  end

  test "can start a child and retrieve it" do
    date = ~D[1989-03-31]
    assert {:ok, pid} = start_child(date)
    assert pid == lookup(date)
  end
end
