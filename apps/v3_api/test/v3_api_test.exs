defmodule V3ApiTest do
  use ExUnit.Case, async: true

  describe "get_json/1" do
    test "normal responses return a JsonApi struct" do
      response = V3Api.get_json("/routes/1")
      assert %JsonApi{} = response
      refute response.data == %{}
    end

    test "missing endpoints return a response" do
      response = V3Api.get_json("/missing")
      refute response.status_code == 200
    end
  end
end
