defmodule Site.ServiceNearMeControllerTest do
  use Site.ConnCase

  alias Site.ServiceNearMeController

  @lat 42.3515322
  @lng -71.0668452
  @address "10 park plaza, boston ma"
  @stop_ids [
    "place-sstat", # commuter
    "place-tumnl", # subway
    "8279" # bus
  ]

  describe "Service Near Me" do
    test "shows no results when params don't contain an address", %{conn: conn} do
      response = conn
      |> get(service_near_me_path(conn, :index))
      |> html_response(200)
      assert response =~ "Find Transit Near You"
      refute response =~ "service-card"
    end

    test "shows results when params contain an address", %{conn: conn} do
      response = conn
      |> search_near_office
      |> html_response(200)
      assert response =~ "Find Transit Near You"
      assert response =~ "service-card"
    end

    test "separates subway lines in response", %{conn: conn} do
      %{assigns: %{stops_with_routes: stops}} = search_near_office(conn)
      assert [%{routes: route_list, stop: %Stops.Stop{}}|_] = stops
      refute Keyword.get(route_list, :commuter_rail) == nil
      refute Keyword.get(route_list, :red_line) == nil
      assert Keyword.get(route_list, :subway) == nil
    end

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

  def mock_response(_) do
    @stop_ids
    |> Enum.map(&Stops.Repo.get/1)
  end

  def search_near_office(conn) do
    search_near_address(conn, @address)
  end

  def search_near_address(conn, address) do
    conn
    |> put_private(:nearby_stops, &mock_response/1)
    |> get(service_near_me_path(conn, :index, %{"location" => %{"address" => address}}))
  end
end
