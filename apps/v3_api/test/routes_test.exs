defmodule V3Api.RoutesTest do
  use ExUnit.Case

  describe "get/1" do
    test "gets the route by ID" do
      bypass = Bypass.open

      url = "http://localhost:#{bypass.port}"

      Bypass.expect bypass, fn conn ->
        assert conn.request_path == "/routes/123"
        Plug.Conn.resp(conn, 200, ~s({"data": []}))
      end

      assert %JsonApi{} = V3Api.Routes.get("123", base_url: url)
    end
  end
end
