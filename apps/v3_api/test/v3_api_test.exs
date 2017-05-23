defmodule V3ApiTest do
  use ExUnit.Case

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
  end
end
