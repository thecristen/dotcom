defmodule SiteWeb.Plugs.RecommendedRoutesTest do
  use SiteWeb.ConnCase, async: true
  alias SiteWeb.Plugs.{RecommendedRoutes, Cookies}
  alias Routes.Route

  describe "call/2" do
    test "assigns list of routes to :recommended_routes if cookie has multiple values", %{conn: conn} do
      cookies = Map.put(%{}, Cookies.route_cookie_name(), "Red|Green|Blue")
      conn =
        conn
        |> Map.put(:cookies, cookies)
        |> RecommendedRoutes.call([])

      assert [
        %Route{} = red,
        %Route{} = green,
        %Route{} = blue
      ] = conn.assigns.recommended_routes

      assert red.id == "Red"
      assert green.id == "Green"
      assert blue.id == "Blue"
    end

    test "assigns one route if cookie has a single value", %{conn: conn} do
      cookies = Map.put(%{}, Cookies.route_cookie_name(), "Red")
      conn =
        conn
        |> Map.put(:cookies, cookies)
        |> RecommendedRoutes.call([])

      assert [%Route{id: "Red"}] = conn.assigns.recommended_routes
    end

    test "does not assign :recommended_routes if cookie doesn't exist", %{conn: conn} do
      conn =
        conn
        |> Map.put(:cookies, %{})
        |> RecommendedRoutes.call([])

      assert Map.fetch(conn.assigns, :recommended_routes) == :error
    end

    test "does not assign :recommended_routes if cookie is empty", %{conn: conn} do
      cookies = Map.put(%{}, Cookies.route_cookie_name(), "")

      conn =
        conn
        |> Map.put(:cookies, cookies)
        |> RecommendedRoutes.call([])

      assert Map.fetch(conn.assigns, :recommended_routes) == :error
    end

    test "does not crash if cookie includes an invalid route id", %{conn: conn} do
      cookies = Map.put(%{}, Cookies.route_cookie_name(), "Red|fail")

      conn =
        conn
        |> Map.put(:cookies, cookies)
        |> RecommendedRoutes.call([])

      assert {:ok, [%Route{id: "Red"}]} = Map.fetch(conn.assigns, :recommended_routes)
    end
  end
end
