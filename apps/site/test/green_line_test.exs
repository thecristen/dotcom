defmodule GreenListTest do
  use ExUnit.Case, async: true

  import GreenLine

  describe "stops_on_routes/0" do
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
end
