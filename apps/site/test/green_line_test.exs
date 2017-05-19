defmodule GreenListTest do
  use ExUnit.Case, async: true

  import GreenLine

  describe "stops_on_routes/1" do
    test "returns ordered stops on the green line by direction ID" do
      {stops, _} = stops_on_routes(0)

      assert %Stops.Stop{id: "place-lech", name: "Lechmere"} = List.first(stops)
      assert %Stops.Stop{id: "place-lake", name: "Boston College"} = List.last(stops)
    end

    test "returns a set of {stop_id, route_id} pairs" do
      {_, route_id_stop_map} = stops_on_routes(1)

      refute "place-lech" in route_id_stop_map["Green-B"]
      refute "place-lech" in route_id_stop_map["Green-C"]
      refute "place-lech" in route_id_stop_map["Green-D"]
      assert "place-lech" in route_id_stop_map["Green-E"]

      assert "place-coecl" in route_id_stop_map["Green-B"]
      assert "place-coecl" in route_id_stop_map["Green-C"]
      assert "place-coecl" in route_id_stop_map["Green-D"]
      assert "place-coecl" in route_id_stop_map["Green-E"]

      assert "place-kencl" in route_id_stop_map["Green-B"]
      assert "place-kencl" in route_id_stop_map["Green-C"]
      assert "place-kencl" in route_id_stop_map["Green-D"]
      refute "place-kencl" in route_id_stop_map["Green-E"]
    end
  end

  describe "all_stops/1" do
    test "can return an error" do
      gl = stops_on_routes(0, ~D[2017-01-01])
      assert {:error, _} = all_stops(gl)
    end
  end

  test "terminus?/2" do
    for stop_id <- ["place-lake", "place-pktrm"] do
      assert terminus?(stop_id, "Green-B")
    end
    for stop_id <- ["place-north", "place-clmnl"] do
      assert terminus?(stop_id, "Green-C")
    end
    for stop_id <- ["place-river", "place-gover"] do
      assert terminus?(stop_id, "Green-D")
    end
    for stop_id <- ["place-lech", "place-hsmnl"] do
      assert terminus?(stop_id, "Green-E")
    end
  end

  test "terminus?/3" do
    assert terminus?("place-lake", "Green-B", 0)
    refute terminus?("place-lake", "Green-B", 1)
    refute terminus?("place-lech", "Green-E", 0)
    assert terminus?("place-lech", "Green-E", 1)
  end

  describe "route_for_stops/1" do
    @stops_on_routes %{
      "Green-B" => ["shared_stop1", "shared_stop2", "b_stop1", "b_stop2"],
      "Green-C" => ["shared_stop1", "shared_stop2", "c_stop1", "c_stop2"],
    }

    test "Returns a map of stop ids associated with the green line routes that stop at that stop" do
      stop_map = routes_for_stops({nil, @stops_on_routes})
      assert "Green-C" in stop_map["shared_stop1"] and "Green-B" in stop_map["shared_stop1"]
      assert "Green-C" in stop_map["shared_stop2"] and "Green-B" in stop_map["shared_stop2"]
      assert stop_map["b_stop2"] == ["Green-B"]
      assert stop_map["c_stop1"] == ["Green-C"]
    end
  end
end
