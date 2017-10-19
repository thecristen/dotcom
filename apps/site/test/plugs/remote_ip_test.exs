defmodule Site.Plugs.RemoteIpTest do
  use Site.ConnCase, async: true

  setup %{conn: conn} do
    %{conn: %{conn | remote_ip: {127, 0, 0, 1}}}
  end

  describe "call/2" do
    test "sets remote_ip when an IP address is in X-Forwarded-For header", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("x-forwarded-for", "18.0.0.1")
        |> Site.Plugs.RemoteIp.call(init())

      assert conn.remote_ip == {18, 0, 0, 1}
    end

    test "uses last IP address when multiple", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("x-forwarded-for", "18.0.0.1, 18.0.0.2")
        |> Site.Plugs.RemoteIp.call(init())

      assert conn.remote_ip == {18, 0, 0, 2}
    end

    test "handles when header is missing", %{conn: conn} do
      assert Site.Plugs.RemoteIp.call(conn, init()).remote_ip == {127, 0, 0, 1}
    end

    test "handles if IP address is malformed", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("x-forwarded-for", "malformed")
        |> Site.Plugs.RemoteIp.call(init())

      assert conn.remote_ip == {127, 0, 0, 1}
    end
  end

  describe "format/1" do
    test "prints IP address correctly" do
      assert Site.Plugs.RemoteIp.format({127, 0, 0, 1}) == "127.0.0.1"
    end
  end

  defp init do
    Site.Plugs.RemoteIp.init([])
  end
end
