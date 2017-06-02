defmodule V3ApiTest do
  use ExUnit.Case

  import Plug.Conn, only: [fetch_query_params: 1, send_resp: 3]

  setup _ do
    bypass = Bypass.open
    old_url = Application.get_env(:v3_api, :base_url)
    old_key = Application.get_env(:v3_api, :api_key)
    on_exit fn ->
      Application.put_env(:v3_api, :base_url, old_url)
      Application.put_env(:v3_api, :api_key, old_key)
    end

    Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")
    {:ok, %{bypass: bypass}}
  end

  describe "get_json/1" do
    test "normal responses return a JsonApi struct", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/normal_response"
        send_resp conn, 200, ~s({"data": []})
      end
      response = V3Api.get_json("/normal_response")
      assert %JsonApi{} = response
      refute response.data == %{}
    end

    test "missing endpoints return an error", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/missing"
        send_resp conn, 404, ~s({"errors":[{"code": "not_found"}]})
      end
      response = V3Api.get_json("/missing")
      assert {:error, [%JsonApi.Error{code: "not_found"}]} = response
    end

    test "can't connect returns an error", %{bypass: bypass} do
      Bypass.down bypass

      response = V3Api.get_json("/cant_connect")
      assert {:error, %{reason: _}} = response
    end

    test "passes an API key if present", %{bypass: bypass} do
      Application.put_env(:v3_api, :api_key, "test_key")
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/with_api_key"
        conn = fetch_query_params(conn)
        assert conn.query_params["api_key"] == "test_key"
        assert conn.query_params["other"] == "value"
        send_resp(conn, 200, "")
      end
      # make sure we keep other params
      V3Api.get_json("/with_api_key", other: "value")
    end

    test "does not pass an API key if not set", %{bypass: bypass} do
      Application.put_env(:v3_api, :api_key, nil)
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/without_api_key"
        refute fetch_query_params(conn).query_params["api_key"]
        send_resp(conn, 200, "")
      end
      V3Api.get_json("/without_api_key")
    end
  end
end
