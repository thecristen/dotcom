defmodule V3Api.StopsTest do
  use ExUnit.Case, async: true

  describe "by_gtfs_id/1" do
    test "gets the parent station info" do
      bypass = Bypass.open
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.params["include"] == "parent_station"
        Plug.Conn.resp(conn, 200, "{}")
      end

      V3Api.Stops.by_gtfs_id("123")
    end
  end
end
