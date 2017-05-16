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
end
