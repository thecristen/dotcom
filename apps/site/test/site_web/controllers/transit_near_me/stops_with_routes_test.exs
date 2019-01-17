defmodule SiteWeb.TransitNearMeController.StopsWithRoutesTest do
  use ExUnit.Case, async: true

  alias Routes.Route
  alias SiteWeb.TransitNearMeController.{RoutesAndStops, StopsWithRoutes}
  alias Stops.Stop

  describe "from_routes_and_stops/1" do
    setup do
      routes_and_stops = %RoutesAndStops{
        join: [
          %{route_id: "Red", stop_id: "9983"},
          %{route_id: "Green-B", stop_id: "9983"},
          %{route_id: "Mattapan", stop_id: "9983"},
          %{route_id: "CR-Commuterrail", stop_id: "9983"},
          %{route_id: "111", stop_id: "9983"},
          %{route_id: "Boat-Ferry", stop_id: "9983"}
        ],
        routes: %{
          "111" => %Route{
            id: "111",
            name: "Bus",
            type: 3
          },
          "Boat-Ferry" => %Route{
            id: "Boat-Ferry",
            name: "Ferry",
            type: 4
          },
          "CR-Commuterrail" => %Route{
            id: "CR-Commuterrail",
            name: "Commuter Rail",
            type: 2
          },
          "Green-B" => %Route{
            id: "Green-B",
            name: "Green Branch",
            type: 0
          },
          "Mattapan" => %Route{
            id: "Mattapan",
            name: "Mattpan Trolley",
            type: 0
          },
          "Red" => %Route{
            id: "Red",
            name: "Red Line",
            type: 1
          }
        },
        stops: %{
          "9983" => %{
            distance: 0.04083664794103045,
            stop: %Stop{id: "9983"}
          }
        }
      }

      %{routes_and_stops: routes_and_stops}
    end

    test "builds a list of stops and the routes that stop at each one", %{
      routes_and_stops: routes_and_stops
    } do
      stops = StopsWithRoutes.from_routes_and_stops(routes_and_stops)

      assert [
               %{
                 stop: stop,
                 distance: distance,
                 routes: routes
               }
             ] = stops

      assert %Stop{} = stop

      assert distance == 0.04083664794103045

      expected_routes = [
        mattapan_trolley: [
          %Route{
            id: "Mattapan",
            name: "Mattpan Trolley",
            type: 0
          }
        ],
        green_line: [
          Route.to_naive(%Route{
            id: "Green-B",
            name: "Green Branch",
            type: 0
          })
        ],
        red_line: [
          %Route{
            id: "Red",
            name: "Red Line",
            type: 1
          }
        ],
        bus: [
          %Route{
            id: "111",
            name: "Bus",
            type: 3
          }
        ],
        commuter_rail: [
          %Route{
            id: "CR-Commuterrail",
            name: "Commuter Rail",
            type: 2
          }
        ],
        ferry: [
          %Route{
            id: "Boat-Ferry",
            name: "Ferry",
            type: 4
          }
        ]
      ]

      assert routes == expected_routes
    end
  end
end
