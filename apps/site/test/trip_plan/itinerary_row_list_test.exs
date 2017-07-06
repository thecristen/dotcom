defmodule Site.TripPlan.ItineraryRowListTest do
  use ExUnit.Case, async: true
  import Site.TripPlan.ItineraryRowList

  @from TripPlan.Api.MockPlanner.random_stop(stop_id: "place-sstat")
  @to TripPlan.Api.MockPlanner.random_stop(stop_id: nil)
  @date_time ~N[2017-06-27T11:43:00]

  describe "from_itinerary" do
    setup do
      {:ok, [itinerary]} = TripPlan.plan(@from, @to, depart_at: @date_time)
      opts = [route_mapper: &route_mapper/1, stop_mapper: &stop_mapper/1, trip_mapper: &trip_mapper/1]
      {:ok, %{itinerary: itinerary, itinerary_row_list: from_itinerary(itinerary, opts), opts: opts}}
    end

    test "ItineraryRow contains stop name and ID if stop_id present", %{itinerary_row_list: itinerary_row_list} do
      rows_with_stops = Enum.filter(itinerary_row_list.rows, fn %{stop: {_name, stop_id}} -> stop_mapper(stop_id) end)
      assert Enum.count(rows_with_stops) > 0
      for %{stop: {stop_name, stop_id}} <- rows_with_stops do
        assert stop_name == stop_mapper(stop_id).name
      end
    end

    test "ItineraryRow contains given stop name when no stop_id present", %{opts: opts} do
      from = TripPlan.Api.MockPlanner.random_stop(stop_id: nil)
      to = TripPlan.Api.MockPlanner.random_stop(stop_id: "place-sstat")
      date_time =  ~N[2017-06-27T11:43:00]
      {:ok, [itinerary]} = TripPlan.plan(from, to, depart_at: date_time)
      itinerary_row_list = from_itinerary(itinerary, opts)

      itinerary_destination = itinerary.legs |> Enum.reject(& &1.from.stop_id) |> List.first |> Map.get(:from)
      row_destination = Enum.find(itinerary_row_list.rows, fn %{stop: {_stop_name, stop_id}} -> is_nil(stop_id) end)
      assert itinerary_destination.name == elem(row_destination.stop, 0)
    end

    test "ItineraryRow contains no consecutive duplicate stops", %{itinerary_row_list: row_list} do
      stops = Enum.map(row_list.rows, & &1.stop)
      assert stops == Enum.dedup(stops)
    end

    test "Rows have departure times of corresponding legs", %{itinerary: itinerary, itinerary_row_list: row_list} do
      for {row, leg} <- Enum.zip(row_list.rows, itinerary.legs) do
        assert row.departure == leg.start
      end
    end

    test "ItineraryRow arrival and departure times increase in ascending order", %{itinerary_row_list: row_list} do
      [origin_arrival | rest_times] = Enum.flat_map(row_list.rows, & [&1.arrival, &1.departure])
      refute origin_arrival
      for {time1, time2} <- Enum.zip(rest_times, Enum.drop(rest_times, 1)) do
        assert Timex.compare(time1, time2) < 1
      end
    end

    test "Destination is the last stop in itinerary", %{itinerary: itinerary, itinerary_row_list: row_list} do
      last_position = itinerary.legs |> List.last() |> Map.get(:to)
      {stop_name, _stop_id, _arrival_time} = row_list.destination
      position_name = case stop_mapper(last_position.stop_id) do
        nil -> last_position.name
        %{name: name} -> name
      end
      assert stop_name == position_name
    end

    test "From stops on ItineraryRowList are not duplicated in intermediate stops", %{itinerary_row_list: row_list} do
      from_stops = MapSet.new(row_list.rows, &elem(&1.stop, 1))
      intermediate_stops = row_list.rows |> Enum.filter(& &1.transit?) |> Enum.flat_map(& &1.steps) |> MapSet.new
      intersection = MapSet.intersection(from_stops, intermediate_stops)
      assert Enum.empty?(intersection)
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
    %Stops.Stop{name: "Repo North Station", id: "place-north"}
  end
  defp stop_mapper("place-sstat") do
    %Stops.Stop{name: "Repo South Station", id: "place-sstat"}
  end
  defp stop_mapper(_) do
    nil
  end

  defp trip_mapper("34170028" = trip_id) do
    %Schedules.Trip{id: trip_id}
  end
  defp trip_mapper(_) do
    %Schedules.Trip{id: "trip_id"}
  end
end
