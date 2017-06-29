defmodule Site.TripPlan.MapTest do
  use ExUnit.Case, async: true
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
      for marker <- map_data.markers do
        assert marker.icon
        assert marker.tooltip
      end
    end

    test "Markers have tooltip of stop name if it exists", %{itinerary: itinerary, map_data: map_data} do
      map_tooltips = Enum.map(map_data.markers, & &1.tooltip)
      stop_ids = Enum.flat_map(itinerary.legs, &[&1.from.stop_id, &1.to.stop_id])
      for stop_id <- stop_ids,
        stop = stop_mapper(stop_id) do
          assert stop.name in map_tooltips
      end
    end

    test "Markers show position name if no stop exisits", %{itinerary: itinerary, map_data: map_data} do
      map_tooltips = Enum.map(map_data.markers, & &1.tooltip)
      for position <- TripPlan.Itinerary.positions(itinerary),
        is_nil(position.stop_id) do
          position.name in map_tooltips
      end
    end
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

  defp stop_mapper("place-north") do
    %Stops.Stop{name: "North Station", id: "place-north"}
  end
  defp stop_mapper("place-bbsta") do
    %Stops.Stop{name: "Back Bay Station", id: "bbsta-north"}
  end
  defp stop_mapper("place-sstat") do
    %Stops.Stop{name: "South Station", id: "place-sstat"}
  end
  defp stop_mapper(_) do
    nil
  end
end
