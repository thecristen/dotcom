defmodule GreenListTest do
  use ExUnit.Case, async: true

  import GreenLine

  describe "stops_on_routes/0" do
    test "returns ordered stops on the green line" do
      {stops, _} = stops_on_routes()

      assert %Stops.Stop{id: "place-lech", name: "Lechmere"} = List.first(stops)
      assert %Stops.Stop{id: "place-lake", name: "Boston College"} = List.last(stops)
    end

    test "returns a set of {stop_id, route_id} pairs" do
      {_, stop_route_id_set} = stops_on_routes()

      refute {"place-lech", "Green-B"} in stop_route_id_set
      refute {"place-lech", "Green-C"} in stop_route_id_set
      refute {"place-lech", "Green-D"} in stop_route_id_set
      assert {"place-lech", "Green-E"} in stop_route_id_set

      assert {"place-coecl", "Green-B"} in stop_route_id_set
      assert {"place-coecl", "Green-C"} in stop_route_id_set
      assert {"place-coecl", "Green-D"} in stop_route_id_set
      assert {"place-coecl", "Green-E"} in stop_route_id_set

      assert {"place-kencl", "Green-B"} in stop_route_id_set
      assert {"place-kencl", "Green-C"} in stop_route_id_set
      assert {"place-kencl", "Green-D"} in stop_route_id_set
      refute {"place-kencl", "Green-E"} in stop_route_id_set
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
