defmodule Predictions.RepoTest do
  use ExUnit.Case
  alias Predictions.Repo
  alias Stops.Stop

  describe "all/1" do
    test "returns a list" do
      predictions = Repo.all(route: "Red")
      assert is_list(predictions)
    end

    test "can filter by route / stop" do
      stops = Repo.all(route: "Red", stop: "place-sstat")
      for stop <- stops do
        assert %{route: %Routes.Route{id: "Red"}, stop: %Stop{id: "place-sstat"}} = stop
      end
    end

    test "can filter by stop / direction" do
      directions = Repo.all(stop: "place-sstat", direction_id: 1)
      for direction <- directions do
        assert %{stop: %Stop{id: "place-sstat"}, direction_id: 1} = direction
      end
    end

    test "can filter by trip" do
      trips = Repo.all(trip: "32542509")
      for prediction <- trips do
        assert prediction.trip.id == "32542509"
      end
    end

    @tag :capture_log
    test "returns a list even if the server is down" do
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:0/")

      assert Repo.all(route: "test_down_server") == []
    end

    @tag :capture_log
    test "returns valid entries even if some don't parse" do
      bypass = Bypass.open
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        # return a Prediction with a valid stop, and one with an invalid stop
        Plug.Conn.resp(conn, 200, ~s(
              {
                "included": [
                  {"type": "route", "id": "Red", "attributes": {"type": 1, "long_name": "Red Line", "direction_names": ["Southbound", "Northbound"], "description": "Rapid Transit"}, "relationships": {}},
                  {"type": "trip", "id": "trip", "attributes": {"headsign": "headsign", "name": "name", "direction_id": "1"}, "relationships": {}},
                  {"type": "stop", "id": "stop", "attributes": {}, "relationships": {}}
                ],
                "data": [
                  {
                    "type": "prediction",
                    "id": "1",
                    "attributes": {
                      "arrival_time": "2016-01-01T00:00:00-05:00"
                    },
                    "relationships": {
                      "route": {"data": {"type": "route", "id": "Red"}},
                      "trip": {"data": {"type": "trip", "id": "trip"}},
                      "stop": null
                    }
                  },
                  {
                    "type": "prediction",
                    "id": "1",
                    "attributes": {
                      "arrival_time": "2016-01-01T00:00:00-05:00"
                    },
                    "relationships": {
                      "route": {"data": {"type": "route", "id": "Red"}},
                      "trip": {"data": {"type": "trip", "id": "trip"}},
                      "stop": {"data": {"type": "stop", "id": "stop"}}
                    }
                  }
                ]
              }))
      end

      refute Repo.all(route: "test_partial_parse") == []
    end
  end
end
