defmodule V3ApiTest do
  use ExUnit.Case, async: true

  import Plug.Conn, only: [fetch_query_params: 1, send_resp: 3]

  setup _ do
    bypass = Bypass.open
    {:ok, %{bypass: bypass, url: "http://localhost:#{bypass.port}"}}
  end

  describe "get_json/1" do
    test "normal responses return a JsonApi struct", %{bypass: bypass, url: url} do
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/normal_response"
        send_resp conn, 200, ~s({"data": []})
      end
      response = V3Api.get_json("/normal_response", [], base_url: url)
      assert %JsonApi{} = response
      refute response.data == %{}
    end

    test "missing endpoints return an error", %{bypass: bypass, url: url} do
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/missing"
        send_resp conn, 404, ~s({"errors":[{"code": "not_found"}]})
      end
      response = V3Api.get_json("/missing", [], base_url: url)
      assert {:error, [%JsonApi.Error{code: "not_found"}]} = response
    end

    test "can't connect returns an error", %{bypass: bypass, url: url} do
      Bypass.down bypass

      response = V3Api.get_json("/cant_connect", [], base_url: url)
      assert {:error, %{reason: _}} = response
    end

    test "passes an API key if present", %{bypass: bypass, url: url} do
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/with_api_key"
        conn = fetch_query_params(conn)
        assert conn.query_params["api_key"] == "test_key"
        assert conn.query_params["other"] == "value"
        send_resp(conn, 200, "")
      end
      # make sure we keep other params
      V3Api.get_json("/with_api_key", [other: "value"], base_url: url, api_key: "test_key")
    end

    test "does not pass an API key if not set", %{bypass: bypass, url: url} do
      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/without_api_key"
        refute fetch_query_params(conn).query_params["api_key"]
        send_resp(conn, 200, "")
      end
      V3Api.get_json("/without_api_key", [], base_url: url, api_key: nil)
    end
  end
end
