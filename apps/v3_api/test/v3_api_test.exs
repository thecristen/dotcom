defmodule V3ApiTest do
  use ExUnit.Case

  import Plug.Conn, only: [fetch_query_params: 1, send_resp: 3]

  describe "get_json/1" do
    test "normal responses return a JsonApi struct" do
      response = V3Api.get_json("/routes/1")
      assert %JsonApi{} = response
      refute response.data == %{}
    end

    test "missing endpoints return an error" do
      response = V3Api.get_json("/missing")
      assert {:error, [%JsonApi.Error{}]} = response
    end

    test "can't connect returns an error" do
      v3_url = Application.get_env(:v3_api, :base_url)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, v3_url)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:0")

      response = V3Api.get_json("/")
      assert {:error, %{reason: _}} = response
    end

    test "passes an API key if present" do
      bypass = Bypass.open
      old_url = Application.get_env(:v3_api, :base_url)
      old_key = Application.get_env(:v3_api, :api_key)
      on_exit fn ->
        Application.put_env(:v3_api, :base_url, old_url)
        Application.put_env(:v3_api, :api_key, old_key)
      end

      Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        refute fetch_query_params(conn).query_params["api_key"]
        send_resp(conn, 200, "")
      end
      V3Api.get_json("/test")

      Application.put_env(:v3_api, :api_key, "test_key")
      Bypass.expect bypass, fn conn ->
        conn = fetch_query_params(conn)
        assert conn.query_params["api_key"] == "test_key"
        assert conn.query_params["other"] == "value"
        send_resp(conn, 200, "")
      end
      # make sure we keep other params
      V3Api.get_json("/test", other: "value")
    end
  end
end
