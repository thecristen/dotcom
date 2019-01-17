defmodule SiteWeb.TransitNearMeController.RoutesAndStopsTest do
  use ExUnit.Case, async: true

  alias GoogleMaps.Geocode.Address
  alias Routes.Route
  alias SiteWeb.TransitNearMeController.RoutesAndStops
  alias Stops.Stop

  def stops_nearby_fn(%Address{}) do
    [
      %Stop{
        id: "9983",
        name: "Stuart St @ Charles St",
        latitude: 42.351039,
        longitude: -71.066798
      }
    ]
  end

  def routes_by_stop_fn("9983") do
    [
      %Route{id: "Red", type: 1, name: "Red Line"},
      %Route{id: "Green-B", type: 0, name: "Green Branch"},
      %Route{id: "Mattapan", type: 0, name: "Mattpan Trolley"},
      %Route{id: "CR-Commuterrail", type: 2, name: "Commuter Rail"},
      %Route{id: "111", type: 3, name: "Bus"},
      %Route{id: "Boat-Ferry", type: 4, name: "Ferry"}
    ]
  end

  @address %Address{
    latitude: 42.351,
    longitude: -71.066,
    formatted: "10 Park Plaza, Boston, MA, 02116"
  }

  describe "get/2" do
    setup do
      opts = [
        stops_nearby_fn: &stops_nearby_fn/1,
        routes_by_stop_fn: &routes_by_stop_fn/1
      ]

      %{opts: opts}
    end

    test "builds a dataset of routes, stops, and joins between the two", %{opts: opts} do
      routes_and_stops = RoutesAndStops.get(@address, opts)

      assert %RoutesAndStops{
               routes: route_map,
               stops: stops_map,
               join: join
             } = routes_and_stops

      expected_stop = @address |> stops_nearby_fn() |> List.first()

      assert stops_map == %{
               "9983" => %{
                 stop: expected_stop,
                 distance: 0.04083664794103045
               }
             }

      expected_routes = routes_by_stop_fn("9983")

      assert route_map == %{
               "Red" => Enum.at(expected_routes, 0),
               "Green-B" => Enum.at(expected_routes, 1),
               "Mattapan" => Enum.at(expected_routes, 2),
               "CR-Commuterrail" => Enum.at(expected_routes, 3),
               "111" => Enum.at(expected_routes, 4),
               "Boat-Ferry" => Enum.at(expected_routes, 5)
             }

      assert join == [
               %{
                 route_id: "Boat-Ferry",
                 stop_id: "9983"
               },
               %{
                 route_id: "111",
                 stop_id: "9983"
               },
               %{
                 route_id: "CR-Commuterrail",
                 stop_id: "9983"
               },
               %{
                 route_id: "Mattapan",
                 stop_id: "9983"
               },
               %{
                 route_id: "Green-B",
                 stop_id: "9983"
               },
               %{
                 route_id: "Red",
                 stop_id: "9983"
               }
             ]
    end
  end
end
