defmodule Site.FareController.CommuterTest do
  use Site.ConnCase

  test "finds fares based on origin and destination" do
    origin = Stations.Repo.get("place-north")
    destination = Stations.Repo.get("Concord")
    conn = build_conn
    |> assign(:origin, origin)
    |> assign(:destination, destination)

    assert Site.FareController.Commuter.fares(conn) == Fares.Repo.all(name: {:zone, "5"})
  end
end
