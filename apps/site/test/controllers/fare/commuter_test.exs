defmodule Site.FareController.CommuterTest do
  use Site.ConnCase

  test "finds fares based on origin and destination" do
    origin = Stations.Repo.get("place-north")
    destination = Stations.Repo.get("Concord")
    assert Site.FareController.Commuter.fares(origin, destination) == Fares.Repo.all(name: {:zone, "5"})
  end
end
