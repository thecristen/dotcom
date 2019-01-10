defmodule SiteWeb.TransitNearMeController.StopsWithRoutesTest do
  use ExUnit.Case, async: true

  alias GoogleMaps.Geocode.Address
  alias Routes.Route
  alias SiteWeb.TransitNearMeController.StopsWithRoutes
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

  describe "get_stops_with_routes/2" do
    test "builds a list of stops and the routes that stop at each one" do
      opts = [
        stops_nearby_fn: &stops_nearby_fn/1,
        routes_by_stop_fn: &routes_by_stop_fn/1
      ]

      stops = StopsWithRoutes.get(@address, opts)

      assert [
               %{
                 stop: stop,
                 distance: distance,
                 routes: routes
               }
             ] = stops

      assert %Stop{} = stop

      assert distance == 0.04083664794103045
      expected_routes = routes_by_stop_fn("9983")

      assert routes == [
               mattapan_trolley: [Enum.at(expected_routes, 2)],
               green_line: [expected_routes |> Enum.at(1) |> Route.to_naive()],
               red_line: [Enum.at(expected_routes, 0)],
               bus: [Enum.at(expected_routes, 4)],
               commuter_rail: [Enum.at(expected_routes, 3)],
               ferry: [Enum.at(expected_routes, 5)]
             ]
    end
  end
end
