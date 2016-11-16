defmodule Predictions.RepoTest do
  use ExUnit.Case
  alias Predictions.Repo

  describe "all/1" do
    test "returns a list" do
      predictions = Repo.all(route: "Red")
      assert is_list(predictions)
    end

    test "can filter by route / stop" do
      stops = Repo.all(route: "Red", stop: "place-sstat")
      for stop <- stops do
        assert %{route_id: "Red", stop_id: "place-sstat"} = stop
      end
    end

    test "can filter by stop / direction" do
      directions = Repo.all(stop: "place-sstat", direction_id: 1)
      for direction <- directions do
        assert %{stop_id: "place-sstat", direction_id: 1} = direction
      end
    end

    @tag :capture_log
    test "returns a list even if the server is down" do
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "")

      assert Repo.all(route: nil) == []
    end
  end
end
