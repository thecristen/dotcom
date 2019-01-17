defmodule SiteWeb.TransitNearMeController.RoutesWithStopsTest do
  use ExUnit.Case, async: true
  alias Routes.Route
  alias SiteWeb.TransitNearMeController.{RoutesAndStops, RoutesWithStops}
  alias Stops.Stop

  describe "from_routes_and_stops/1" do
    setup do
      routes_and_stops = %RoutesAndStops{
        join: [
          %{route_id: "43", stop_id: "1241"},
          %{route_id: "39", stop_id: "9983"},
          %{route_id: "55", stop_id: "9983"},
          %{route_id: "57", stop_id: "9983"},
          %{route_id: "504", stop_id: "9983"},
          %{route_id: "553", stop_id: "9983"},
          %{route_id: "43", stop_id: "8281"},
          %{route_id: "Green", stop_id: "place-pktrm"},
          %{route_id: "Red", stop_id: "place-pktrm"}
        ],
        routes: %{
          "43" => %Route{id: "43"},
          "39" => %Route{id: "39"},
          "55" => %Route{id: "55"},
          "57" => %Route{id: "57"},
          "504" => %Route{id: "504"},
          "553" => %Route{id: "553"},
          "Green" => %Route{id: "Green"},
          "Red" => %Route{id: "Red"}
        },
        stops: %{
          "1241" => %{
            distance: 0.0198223066741451,
            stop: %Stop{id: "1241"}
          },
          "9983" => %{
            distance: 0.03416199740798695,
            stop: %Stop{id: "9983"}
          },
          "8281" => %{
            distance: 0.15122232179123676,
            stop: %Stops.Stop{id: "8281"}
          },
          "place-pktrm" => %{
            distance: 0.4047822867665245,
            stop: %Stop{id: "place-pktrm"}
          }
        }
      }

      %{routes_and_stops: routes_and_stops}
    end

    test "transforms a list of stop_with_routes, to a list of routes_with_stops", %{
      routes_and_stops: routes_and_stops
    } do
      expected_result = [
        %{
          route: %Routes.Route{id: "39"},
          stops: [
            %{
              stop: %Stops.Stop{id: "9983"},
              distance: 0.03416199740798695
            }
          ]
        },
        %{
          route: %Routes.Route{id: "43"},
          stops: [
            %{
              stop: %Stops.Stop{id: "1241"},
              distance: 0.0198223066741451
            },
            %{
              stop: %Stops.Stop{id: "8281"},
              distance: 0.15122232179123676
            }
          ]
        },
        %{
          route: %Routes.Route{id: "504"},
          stops: [
            %{
              stop: %Stops.Stop{id: "9983"},
              distance: 0.03416199740798695
            }
          ]
        },
        %{
          route: %Routes.Route{id: "55"},
          stops: [
            %{
              stop: %Stops.Stop{id: "9983"},
              distance: 0.03416199740798695
            }
          ]
        },
        %{
          route: %Routes.Route{id: "553"},
          stops: [
            %{
              stop: %Stops.Stop{id: "9983"},
              distance: 0.03416199740798695
            }
          ]
        },
        %{
          route: %Routes.Route{id: "57"},
          stops: [
            %{
              stop: %Stops.Stop{id: "9983"},
              distance: 0.03416199740798695
            }
          ]
        },
        %{
          route: %Routes.Route{id: "Green"},
          stops: [
            %{
              stop: %Stops.Stop{id: "place-pktrm"},
              distance: 0.4047822867665245
            }
          ]
        },
        %{
          route: %Routes.Route{id: "Red"},
          stops: [
            %{
              stop: %Stops.Stop{id: "place-pktrm"},
              distance: 0.4047822867665245
            }
          ]
        }
      ]

      assert RoutesWithStops.from_routes_and_stops(routes_and_stops) == expected_result
    end
  end
end
