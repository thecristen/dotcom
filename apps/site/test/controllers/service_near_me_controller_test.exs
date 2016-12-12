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

  describe "put_flash_if_error/2" do
    test "does nothing if there are stops_with_routes", %{conn: conn} do
      conn = conn
      |> assign(:stops_on_routes, [{%Stops.Stop{}, []}])
      |> assign(:address, "address")
      assert Site.ServiceNearMeController.flash_if_error(conn) == conn
    end

    test "shows message if there's no address", %{conn: conn} do
      conn = conn
             |> assign(:address, "")
             |> bypass_through(Site.Router, :browser)
             |> get("/")
             |> Site.ServiceNearMeController.flash_if_error()

      assert Phoenix.Controller.get_flash(conn)["info"] =~ "No address"
    end
  end

  def search_near_address(conn, address) do
    conn
    |> assign(:stops_with_routes, [])
    |> assign(:address, address)
    |> Phoenix.Controller.put_view(Site.ServiceNearMeView)
    |> bypass_through(Site.Router, :browser)
    |> get("/")
    |> Site.ServiceNearMeController.index([])
  end
end
