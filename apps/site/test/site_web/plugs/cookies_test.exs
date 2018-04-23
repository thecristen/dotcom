defmodule SiteWeb.Plugs.CookiesTest do
  @moduledoc false
  use SiteWeb.ConnCase, async: true
  import SiteWeb.Plugs.Cookies

  describe "call/2" do
    test "creates a mbta_id cookie", %{conn: conn} do
      conn = %{conn | cookies: %{}}
      conn = call(conn, [])

      assert Map.has_key?(conn.cookies, "mbta_id")
    end

    test "does not create a new cookie if it exists", %{conn: conn} do
      conn = %{conn | cookies: %{"mbta_key" => "123"}}
      conn = call(conn, [])

      assert Map.has_key?(conn.cookies, "mbta_id")
      assert conn.cookies["mbta_key"] == "123"
    end
  end
end
