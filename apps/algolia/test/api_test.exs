defmodule Algolia.ApiTest do
  use ExUnit.Case

  @request ~s({"requests" : [{"indexName" : "index"}]})
  @success_response ~s({"message" : "success"})

  describe "post" do
    test "sends a post request to /1/indexes/$INDEX/$ACTION" do
      bypass = Bypass.open()
      Bypass.expect(bypass, "POST", "/1/indexes/*/queries", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        case Poison.decode(body) do
          {:ok, %{"requests" => [%{"indexName" => "index_test"}]}} ->
            Plug.Conn.send_resp(conn, 200, @success_response)
          _ ->
            Plug.Conn.send_resp(conn, 400, ~s({"error" : "bad request"}))
        end
      end)

      opts = %Algolia.Api{
        host: "http://localhost:#{bypass.port}",
        index: "*",
        action: "queries",
        body: @request
      }

      assert {:ok, %HTTPoison.Response{status_code: 200, body: body}} = Algolia.Api.post(opts)
      assert body == @success_response
    end
  end
end
