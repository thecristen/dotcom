defmodule V3ApiTest do
  use ExUnit.Case, async: true

  describe "get_json/1" do
    test "normal responses return a JsonApi struct" do
      response = V3Api.get_json("/routes/1")
      assert %JsonApi{} = response
      refute response.data == %{}
    end

    test "missing endpoints return an error" do
      response = V3Api.get_json("/missing")
      assert {:error, httpoison_response} = response
      assert {"Content-Encoding", "gzip"} =
        List.keyfind(httpoison_response.headers, "Content-Encoding", 0)
    end
  end
end
