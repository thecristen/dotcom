defmodule Site.TripPlan.MapTest do
  use ExUnit.Case, async: true
  alias Stops.Position
  alias TripPlan.Itinerary
  import Site.TripPlan.Map

  @from TripPlan.Api.MockPlanner.random_stop(stop_id: "place-sstat")
  @to TripPlan.Api.MockPlanner.random_stop(stop_id: nil)
  @date_time ~N[2017-06-27T11:43:00]

  describe "itinerary_map/3" do
    setup do
      {:ok, [itinerary]} = TripPlan.plan(@from, @to, depart_at: @date_time)
      {map_data, _static_url} = itinerary_map(itinerary, [route_mapper: &route_mapper/1, stop_mapper: &stop_mapper/1])
      {:ok, %{itinerary: itinerary, map_data: map_data}}
    end

    test "All markers have icons and tooltips", %{map_data: map_data} do
      refute Enum.empty?(map_data.markers)
      for marker <- map_data.markers do
        assert marker.icon
        assert marker.tooltip
      end
    end

    test "Markers have tooltip of stop name if it exists", %{itinerary: itinerary, map_data: map_data} do
      map_tooltips = Enum.map(map_data.markers, & &1.tooltip)
      stops = itinerary |> Itinerary.stop_ids() |> Enum.map(&stop_mapper/1) |> Enum.filter(& &1)
      refute Enum.empty?(stops)
      assert Enum.all?(stops, & &1.name in map_tooltips)
    end

    test "z index is 1 if leg has a route", %{itinerary: itinerary, map_data: map_data} do
      assert Enum.count(itinerary) == 2
      assert [_route_id] = Itinerary.route_ids(itinerary)
      assert markers_with_z_index(0, map_data.markers) == 2
      assert markers_with_z_index(1, map_data.markers) == 2
    end

    test "prepends the 'from' and appends the 'to' locations to the polyline",
         %{itinerary: itinerary, map_data: map_data} do

      polylines = Enum.map(map_data.paths, &Polyline.decode(&1.polyline))
      o_d_pairs = Enum.map(itinerary.legs, fn %{from: from, to: to} ->
        {{Position.longitude(from), Position.latitude(from)},
         {Position.longitude(to), Position.latitude(to)}}
      end)

      assert Enum.count(polylines) == Enum.count(itinerary.legs)
      for {line, {from, to}} <- Enum.zip(polylines, o_d_pairs) do
        {from_lon, from_lat} = from
        {to_lon, to_lat} = to
        {lon_1, lat_1} = List.first(line)
        {lon_2, lat_2} = List.last(line)
        assert_in_delta from_lon, lon_1, 0.00001
        assert_in_delta from_lat, lat_1, 0.00001
        assert_in_delta to_lon, lon_2, 0.00001
        assert_in_delta to_lat, lat_2, 0.00001
      end
    end
  end

  defp markers_with_z_index(idx, markers) do
    markers
    |> Enum.filter(& &1.z_index == idx)
    |> Enum.count
  end

  defp route_mapper("Blue" = id) do
    %Routes.Route{type: 1, id: id, name: "Subway"}
  end
  defp route_mapper("CR-Lowell" = id) do
    %Routes.Route{type: 2, id: id, name: "Commuter Rail"}
  end
  defp route_mapper("1" = id) do
    %Routes.Route{type: 3, id: id, name: "Bus"}
  end
  defp route_mapper(_) do
    nil
  end

  defp stop_mapper("North Station") do
    %Stops.Stop{name: "North Station", id: "place-north"}
  end
  defp stop_mapper("place-sstat") do
    %Stops.Stop{name: "South Station", id: "place-sstat"}
  end
  defp stop_mapper(_) do
    nil
  end
end
