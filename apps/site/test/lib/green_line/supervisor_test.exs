defmodule Site.GreenLine.CacheSupervisorTest do
  use ExUnit.Case

  test "CacheSupervisor is started along with registry" do
    assert {:error, {:already_started, _}} = Site.GreenLine.CacheSupervisor.start_link()
    assert {:error, {:already_started, _}} = Registry.start_link(:unique, :green_line_cache_registry)
  end
end
