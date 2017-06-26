defmodule Vehicles.RepoTest do
  use ExUnit.Case
  alias Vehicles.{Repo, Vehicle}

  describe "route/1" do
    test "given a route ID, finds vehicle statuses for that route" do
      vehicles = Repo.route("86")
      for vehicle <- vehicles do
        assert match?(%Vehicle{route_id: "86"}, vehicle)
      end
    end

    test "if there are no vehicles on the route, returns the empty list" do
      assert Repo.route("bogus") == []
    end

    test "optionally takes a direction_id parameter" do
      vehicles = Repo.route("CR-Lowell", direction_id: 1)
      for vehicle <- vehicles do
        assert match?(%Vehicle{route_id: "CR-Lowell", direction_id: 1}, vehicle)
      end
    end

    test "returns an empty list when the API errors" do
      bypass = Bypass.open()
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 500, "Whops!")
      end

      assert Repo.route("not-a-route") == []
    end
  end

  describe "trip/1" do
    test "if there is no vehicle status for a trip, returns nil" do
      assert Repo.trip("bogus") == nil
    end

    test "returns the status for a single trip if it is available" do
      bypass = Bypass.open()
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

      trip_id = "32884079"
      vehicle_id = "y0319"
      stop_id = "22549"
      route_id = "86"

      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, ~s(
              {
                "jsonapi": {
                  "version": "1.0"
                },
                "data": [
                  {
                    "type": "vehicle",
                    "relationships": {
                      "trip": {
                        "data": {
                          "type": "trip",
                          "id": "#{trip_id}"
                        }
                      },
                      "stop": {
                        "data": {
                          "type": "stop",
                          "id": "#{stop_id}"
                        }
                      },
                      "route": {
                        "data": {
                          "type": "route",
                          "id": "#{route_id}"
                        }
                      }
                    },
                    "links": {
                      "self": "/vehicles/#{vehicle_id}"
                    },
                    "id": "#{vehicle_id}",
                    "attributes": {
                      "direction_id": 1,
                      "current_status": "INCOMING_AT"
                    }
                  }
                ]
              }
            )
        )
      end

      expected = %Vehicle{
        id: vehicle_id,
        route_id: route_id,
        stop_id: stop_id,
        trip_id: trip_id,
        direction_id: 1,
        status: :incoming
      }

      assert Repo.trip(trip_id) == expected
    end
  end
end
