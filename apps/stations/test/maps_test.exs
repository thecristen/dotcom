defmodule Stations.MapsTest do
  use ExUnit.Case, async: true

  test "returns a URL if there's a map for the station" do
    url = Stations.Maps.by_name("South Station")
    assert "http://www.mbta.com" <> _ = url
  end

  test "returns an empty string if there is not a map" do
    url = Stations.Maps.by_name("Framingham")
    assert url == ""
  end
end
