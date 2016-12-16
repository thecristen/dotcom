defmodule Site.TransitNearMeControllerTest do
  use Site.ConnCase, async: true

  describe "Transit Near Me" do
    test "display message if no address", %{conn: conn} do
      response = conn
      |> search_near_address("")
      |> html_response(200)
      assert response =~ "No address provided"
    end

    test "display message if no results", %{conn: conn} do
      response = conn
      |> search_near_address("randomnonsensicalstringnoresults")
      |> html_response(200)
      assert response =~ "any stations found"
    end
  end

  @spec search_near_address(Plug.Conn.t, String.t) :: Plug.Conn.t
  def search_near_address(conn, address) do
    conn
    |> assign(:stops_with_routes, [])
    |> assign(:address, address)
    |> Phoenix.Controller.put_view(Site.TransitNearMeView)
    |> bypass_through(Site.Router, :browser)
    |> get("/")
    |> Site.Plugs.TransitNearMe.call(Site.Plugs.TransitNearMe.init([]))
    |> Site.TransitNearMeController.index([])
  end
end
