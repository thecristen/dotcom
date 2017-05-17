defmodule Stops.RepoTest do
  use ExUnit.Case, async: true

  import Stops.Repo
  alias Stops.Stop

  describe "by_route/3" do
    test "returns a list of stops in order of their stop_sequence" do
      response = by_route("CR-Lowell", 1)

      assert response != []
      assert match?(%Stop{id: "Lowell", name: "Lowell"}, List.first(response))
      assert match?(%Stop{id: "place-north", name: "North Station"}, List.last(response))
      assert response == Enum.uniq(response)
    end

    test "uses the parent station name" do
      response = by_route("Green-B", 1)

      assert response != []
      assert match?(%Stop{id: "place-lake", name: "Boston College"}, List.first(response))
      assert Enum.filter(response, &match?(%Stop{name: "South Street", id: "place-sougr"}, &1)) != []
    end

    test "does not include a parent station multiple times" do
      # stops multiple times at Sullivan
      response = by_route("86", 1)

      assert response != []
      refute (response |> Enum.at(1)).id == "place-sull"
    end

    test "can take additional fields" do
      today = Timex.today()
      weekday = today |> Timex.shift(days: 7) |> Timex.beginning_of_week(:fri)
      saturday = weekday |> Timex.shift(days: 1)

      assert by_route("CR-Providence", 1, date: weekday) != by_route("CR-Providence", 1, date: saturday)
    end
  end

  describe "by_routes/3" do
    test "can return stops from multiple route IDs" do
      response = by_routes(["CR-Lowell", "CR-Haverhill"], 1)
      assert Enum.find(response, & &1.id == "Lowell")
      assert Enum.find(response, & &1.id == "Haverhill")
      # North Station only appears once
      assert response |> Enum.filter(& &1.id == "place-north") |> length == 1
    end
  end

  describe "by_route_type/2" do
    test "can returns stops filtered by route type" do
      response = by_route_type(2) # commuter rail
      assert Enum.find(response, & &1.id == "Lowell")
      assert Enum.find(response, & &1.id == "place-north")
      # doesn't include non-CR stops
      refute Enum.find(response, & &1.id == "place-boyls")
    end
  end

  describe "stop_features/1" do
    @stop %Stop{id: "place-sstat"}
    test "Returns stop features for a given stop" do
      features = stop_features(@stop)
      assert :commuter_rail in features
      assert :red_line in features
      assert :bus in features
    end

    test "returns stop features in correct order" do
      assert stop_features(@stop) == [:commuter_rail, :red_line, :bus]
    end

    test "accessibility added if relevant" do
      features = stop_features(%{@stop | accessibility: ["accessible"]})
      assert features == [:commuter_rail, :red_line, :bus, :access]
    end

    test "adds parking features if relevant" do
      stop = %{@stop | parking_lots: [%Stop.ParkingLot{}]}
      assert :parking_lot in stop_features(stop)
    end
  end
end
