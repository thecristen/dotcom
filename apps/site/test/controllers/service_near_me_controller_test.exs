defmodule Site.ServiceNearMeControllerTest do
  use Site.ConnCase

  describe "Service Near Me" do
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

  def search_near_address(conn, address) do
    conn
    |> assign(:stops_with_routes, [])
    |> assign(:address, address)
    |> Phoenix.Controller.put_view(Site.ServiceNearMeView)
    |> bypass_through(Site.Router, :browser)
    |> get("/")
    |> Site.Plugs.ServiceNearMe.call(Site.Plugs.ServiceNearMe.init([]))
    |> Site.ServiceNearMeController.index([])
  end
end
