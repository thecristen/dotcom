defmodule Site.FareController.CommuterTest do
  use Site.ConnCase

  test "finds fares based on origin and destination" do
    conn = build_conn(:get, fare_path(Site.Endpoint, :commuter), origin: "place-north", destination: "Concord")
    assert Site.FareController.Commuter.fares(conn).assigns[:fares] == Fares.Repo.all(name: {:zone, "5"})
  end
end
