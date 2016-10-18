defmodule Site.FareController.CommuterTest do
  use Site.ConnCase

  test "finds fares based on origin and destination" do
    assert Site.FareController.Commuter.fares("place-north", "Concord") == Fares.Repo.all(name: {:zone, "5"})
  end
end
