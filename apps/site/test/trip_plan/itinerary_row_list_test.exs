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
      for {row, leg} <- Enum.zip(row_list, itinerary) do
        assert row.departure == leg.start
      end
    end

    test "ItineraryRow departure times increase in ascending order", %{itinerary_row_list: row_list} do
      assert Enum.sort_by(row_list.rows, & &1.departure, &Timex.before?/2) == row_list.rows
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

    test "Distance is given with personal steps", %{itinerary: itinerary, opts: opts} do
      leg = TripPlan.Api.MockPlanner.personal_leg(@from, @to, @date_time, Timex.shift(@date_time, minutes: 15))
      personal_itinerary = %{itinerary | legs: [leg]}
      row_list = from_itinerary(personal_itinerary, opts)
      for {_step, distance} <- Enum.flat_map(row_list, & &1.steps) do
        assert distance
      end
    end

    test "Distance not given for transit steps", %{itinerary_row_list: row_list} do
      for itinerary_row <- row_list, itinerary_row.transit? do
        for {_step, distance} <- itinerary_row.steps do
          refute distance
        end
      end
    end

    test "Uses to name when one is provided", %{itinerary: itinerary, opts: opts} do
      user_opts = Keyword.merge(opts, [to: "Final Destination"])
      {destination, stop_id, _datetime} = from_itinerary(itinerary, user_opts).destination
      assert destination == "Final Destination"
      refute stop_id
    end

    test "Does not replace to stop_id", %{opts: opts} do
      to = TripPlan.Api.MockPlanner.random_stop(stop_id: "place-north")
      {:ok, [itinerary]} = TripPlan.plan(@from, to, depart_at: @date_time)
      user_opts = Keyword.merge(opts, [to: "Final Destination"])
      {name, id, _datetime} = itinerary |> from_itinerary(user_opts) |> Map.get(:destination)
      assert name == "Final Destination"
      assert id == "place-north"
    end

    test "Uses given from name when one is provided", %{opts: opts} do
      from = TripPlan.Api.MockPlanner.random_stop(stop_id: nil)
      {:ok, [itinerary]} = TripPlan.plan(from, @to, depart_at: @date_time)
      user_opts = Keyword.merge(opts, [from: "Starting Point"])
      {name, nil} = itinerary |> from_itinerary(user_opts) |> Enum.at(0) |> Map.get(:stop)
      assert name == "Starting Point"
    end

    test "Does not replace from stop_id", %{itinerary: itinerary, opts: opts} do
      user_opts = Keyword.merge(opts, [from: "Starting Point"])
      {name, id} = itinerary |> from_itinerary(user_opts) |> Enum.at(0) |> Map.get(:stop)
      assert name == "Starting Point"
      assert id == "place-sstat"
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
