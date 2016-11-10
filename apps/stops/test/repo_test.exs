defmodule Stops.RepoTest do
  use ExUnit.Case, async: true

  describe "find_closest/4" do
    test "given a list of stops, returns a list of the closest 1" do
      stops = %JsonApi{data: [
        %JsonApi.Item{attributes: %{"latitude" => 42.593248,
           "longitude" => -71.280995, "name" => "North Billerica",
           "wheelchair_boarding" => 1}, id: "North Billerica",
         relationships: %{"parent_station" => []}, type: "stop"},
        %JsonApi.Item{attributes: %{"latitude" => 42.546624,
           "longitude" => -71.174334, "name" => "Wilmington",
           "wheelchair_boarding" => 1}, id: "Wilmington",
         relationships: %{"parent_station" => []}, type: "stop"},
        %JsonApi.Item{attributes: %{"latitude" => 42.518926,
           "longitude" => -71.252597, "name" => "Bedford Wood Dr @ Bldg 174",
           "wheelchair_boarding" => 0}, id: "49795",
         relationships: %{"parent_station" => []}, type: "stop"},
        %JsonApi.Item{attributes: %{"latitude" => 42.518651,
           "longitude" => -71.247852, "name" => "Oak Park Dr @ HSG",
           "wheelchair_boarding" => 0}, id: "49796",
         relationships: %{"parent_station" => []}, type: "stop"}], links: %{}}

      assert Stops.Repo.find_closest(stops, 42.57, -71.22, 1) == [Stops.Repo.get("Wilmington")]
    end

    test "gets the closest 12 stops when no number is given" do
      stops = %JsonApi{data: [
        %JsonApi.Item{attributes: %{"latitude" => 42.593248, "longitude" => -65.280995}, id: "stop_1"},
        %JsonApi.Item{attributes: %{"latitude" => 43.593248, "longitude" => -66.280995}, id: "stop_2"},
        %JsonApi.Item{attributes: %{"latitude" => 44.593248, "longitude" => -67.280995}, id: "stop_3"},
        %JsonApi.Item{attributes: %{"latitude" => 45.593248, "longitude" => -68.280995}, id: "stop_4"},
        %JsonApi.Item{attributes: %{"latitude" => 46.593248, "longitude" => -69.280995}, id: "stop_5"},
        %JsonApi.Item{attributes: %{"latitude" => 47.593248, "longitude" => -71.280995}, id: "stop_6"},
        %JsonApi.Item{attributes: %{"latitude" => 48.593248, "longitude" => -70.280995}, id: "stop_7"},
        %JsonApi.Item{attributes: %{"latitude" => 49.593248, "longitude" => -71.280995}, id: "stop_8"},
        %JsonApi.Item{attributes: %{"latitude" => 50.593248, "longitude" => -72.280995}, id: "stop_9"},
        %JsonApi.Item{attributes: %{"latitude" => 51.593248, "longitude" => -73.280995}, id: "stop_10"},
        %JsonApi.Item{attributes: %{"latitude" => 52.593248, "longitude" => -74.280995}, id: "stop_11"},
        %JsonApi.Item{attributes: %{"latitude" => 53.593248, "longitude" => -75.280995}, id: "stop_12"},
        %JsonApi.Item{attributes: %{"latitude" => 54.593248, "longitude" => -76.280995}, id: "stop_13"},
        %JsonApi.Item{attributes: %{"latitude" => 55.593248, "longitude" => -77.280995}, id: "stop_14"},
        %JsonApi.Item{attributes: %{"latitude" => 56.593248, "longitude" => -78.280995}, id: "stop_15"},
        %JsonApi.Item{attributes: %{"latitude" => 57.593248, "longitude" => -79.280995}, id: "stop_16"}
      ]}

      assert Enum.count(Stops.Repo.find_closest(stops, 42.57, -71.22)) == 12
    end
  end
end
