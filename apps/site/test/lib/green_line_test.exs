defmodule GreenLineTest do
  use ExUnit.Case
  import GreenLine

  describe "calculate_stops_on_routes/1" do
    def stops_fn(route, _, _) do
      case route do
        "Green-B" -> []
        "Green-C" ->
          [%Stops.Stop{id: "place-clmnl"},
           %Stops.Stop{id: "place-gover"},
           %Stops.Stop{id: "place-north"}
          ]
        "Green-D" ->
          [%Stops.Stop{id: "place-river"},
           %Stops.Stop{id: "place-gover"}
          ]
        "Green-E" ->
          [%Stops.Stop{id: "place-hsmnl"},
           %Stops.Stop{id: "place-gover"},
           %Stops.Stop{id: "place-north"},
           %Stops.Stop{id: "place-lech"}
          ]
      end
    end

    test "each line returns a set of the ids of associated stops" do
      {_, stop_map} = calculate_stops_on_routes(0, Timex.today(), &stops_fn/3)

      assert stop_map["Green-C"] == MapSet.new(["place-clmnl", "place-gover", "place-north"])
      assert stop_map["Green-D"] == MapSet.new(["place-river", "place-gover"])
      assert stop_map["Green-E"] == MapSet.new(["place-hsmnl", "place-gover", "place-north", "place-lech"])
    end

    test "a list of stops without duplicates is returned" do
      {stops, _} = calculate_stops_on_routes(0, Timex.today(), &stops_fn/3)

      assert Enum.sort(stops) == Enum.sort([%Stops.Stop{id: "place-hsmnl"},
                                            %Stops.Stop{id: "place-gover"},
                                            %Stops.Stop{id: "place-north"},
                                            %Stops.Stop{id: "place-lech"},
                                            %Stops.Stop{id: "place-clmnl"},
                                            %Stops.Stop{id: "place-river"}
                                          ])
    end

    test "if a line returns no stops, it is represented in the map by an empty set" do
      {_, stop_map} = calculate_stops_on_routes(0, Timex.today(), &stops_fn/3)

      assert stop_map["Green-B"] == MapSet.new()
    end
  end
end
