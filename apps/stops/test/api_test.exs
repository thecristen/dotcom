defmodule Stops.ApiTest do
  use ExUnit.Case
  import Stops.Api
  alias Stops.Stop

  test "all returns more than 25 items" do
    assert length(all()) > 25
    assert all() == Enum.uniq(all())
  end

  describe "by_gtfs_id/1" do
    test "uses the gtfs ID to find a stop" do
      {:ok, stop} = by_gtfs_id("Anderson/ Woburn")

      assert stop.id == "Anderson/ Woburn"
      assert stop.name == "Anderson/Woburn"
      assert stop.station?
      assert stop.accessibility != []
      assert stop.parking_lots != []
      for parking_lot <- stop.parking_lots do
        assert %Stop.ParkingLot{} = parking_lot
        assert parking_lot.spots != nil
        manager = parking_lot.manager
        assert manager.name == "Massport"
      end
    end

    test "can use the GTFS accessibility data" do
      {:ok, stop} = by_gtfs_id("Yawkey")
      assert ["accessible" | _] = stop.accessibility
    end

    test "returns nil if stop is not found" do
      assert by_gtfs_id("-1") == {:ok, nil}
    end

    test "returns a stop even if the stop is not a station" do
      {:ok, stop} = by_gtfs_id("411")

      assert stop.id == "411"
      assert stop.name == "Warren St @ Brunswick St"
      assert stop.latitude != nil
      assert stop.longitude != nil
      refute stop.station?
    end

    test "returns an error if the API returns an error" do
      bypass = Bypass.open
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      assert {:error, _} = by_gtfs_id("error stop")
    end
  end

  test "by_route returns an error tuple if the V3 API returns an error" do
    bypass = Bypass.open
    v3_url = Application.get_env(:v3_api, :base_url)
    on_exit fn ->
      Application.put_env(:v3_api, :base_url, v3_url)
    end

    Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

    Bypass.expect bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end

    assert {:error, _} = by_route({"1", 0, []})
  end

  describe "merge_v3/2" do
    test "wheelchair_boarding == 0: not known, not accessible" do
      {:ok, merged} = merge_v3(%Stop{}, {:ok, %JsonApi.Item{attributes: %{"wheelchair_boarding" => 0}}})
      refute Stop.accessibility_known?(merged)
      refute Stop.accessible?(merged)
    end

    test "wheelchair_boarding == 1: known and accessible" do
      {:ok, merged} = merge_v3(%Stop{}, {:ok, %JsonApi.Item{attributes: %{"wheelchair_boarding" => 1}}})
      assert Stop.accessibility_known?(merged)
      assert Stop.accessible?(merged)
    end

    test "wheelchair_boarding == 2: known but not accessible" do
      {:ok, merged} = merge_v3(%Stop{}, {:ok, %JsonApi.Item{attributes: %{"wheelchair_boarding" => 2}}})
      assert Stop.accessibility_known?(merged)
      refute Stop.accessible?(merged)
    end
  end
end
