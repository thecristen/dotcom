defmodule Stations.ApiTest do
  use ExUnit.Case, async: true

  alias Stations.Station

  test "all returns more than 25 items" do
    all = Stations.Api.all
    assert length(all) > 25
    assert all == Enum.uniq(all)
  end

  test "by_gtfs_id uses the gtfs parameter" do
    station = Stations.Api.by_gtfs_id("Anderson/ Woburn")

    assert station.id == "Anderson/ Woburn"
    assert station.name == "Anderson/Woburn"
    assert station.accessibility != []
    assert station.parking_lots != []
    for parking_lot <- station.parking_lots do
      assert %Station.ParkingLot{} = parking_lot
      assert parking_lot.spots != nil
      manager = parking_lot.manager
      assert manager.name == "Massport"
    end
  end

  test "by_gtfs_id returns nil if station is not found" do
    assert Stations.Api.by_gtfs_id("-1") == nil
  end
end
