defmodule Site.Plugs.ServiceNearMeTest do
  use Site.ConnCase

  import Site.Plugs.ServiceNearMe

  alias Site.Plugs.ServiceNearMe.Options
  alias Routes.Route
  alias Stops.Stop
  alias GoogleMaps.Geocode

  @address "10 park plaza, boston ma"
  @stop_ids [
    "place-sstat", # commuter
    "place-tumnl", # subway
    "8279" # bus
  ]

  describe "call/2" do
    test "separates subway lines in response", %{conn: conn} do
      %{assigns: %{stops_with_routes: stops}} = search_near_office(conn)
      assert [%{routes: route_list, stop: %Stops.Stop{}}|_] = stops
      refute Keyword.get(route_list, :commuter_rail) == nil
      refute Keyword.get(route_list, :red_line) == nil
      assert Keyword.get(route_list, :subway) == nil
    end

    test "assigns address and stops with routes", %{conn: conn} do
      options = %Options{nearby_fn: &mock_response/1}

      conn = conn
      |> assign_query_params(%{"location" => %{"address" => @address}})
      |> fetch_query_params
      |> call(options)

      assert :stops_with_routes in Map.keys conn.assigns
      assert :address in Map.keys conn.assigns
    end

    test "assigns no stops and empty address if none is provided", %{conn: conn} do
      conn = conn
      |> assign_query_params(%{})
      |> call(%Options{})

      assert conn.assigns.stops_with_routes == []
      assert conn.assigns.address == ""
    end
  end

  describe "init/1" do
    test "it returns a default options struct" do
      assert init([]) == %Options{}
    end
  end

  describe "assign_stops_with_routes/2" do
    test "it assigns the stops_with routes on the conn", %{conn: conn} do
      stops_with_routes = [%{stop: %Stop{}, routes: [%Route{}]}]

      conn = conn
      |> assign_stops_with_routes(stops_with_routes)

      assert :stops_with_routes in Map.keys conn.assigns
    end
  end

  describe "assign_address/2" do
    test "it assigns address on the conn", %{conn: conn} do
      address = "10 Park Plaza"

      conn = conn
      |> assign_address(address)

      assert :address in Map.keys conn.assigns
    end
  end

  describe "get_stops_nearby/2" do
    test "with a good geocode result, calls function with first result" do
      geocode_result = {:ok, [%Geocode.Address{}]}
      nearby = fn(%Geocode.Address{}) -> [%Stop{}] end

      actual = get_stops_nearby(geocode_result, nearby)
      expected = [%Stop{}]

      assert actual == expected
    end

    test "when there are errors, returns an empty list" do
      geocode_result = {:error, :unknown_error, ["error"]}
      nearby = fn(%Geocode.Address{}) -> [%Stop{}] end

      actual = get_stops_nearby(geocode_result, nearby)
      expected = []

      assert actual == expected
    end
  end

  describe "get_route_groups/1" do
    test "regroups subway into indiviual entries" do
      red_line = %Route{id: "Red", name: "Red", type: 1}
      green_line = %Route{id: "Green-B", name: "Green-B", type: 0}
      route_list = [green_line, red_line]

      assert get_route_groups(route_list) |> Enum.sort == [
        green_line: [%Route{id: "Green", name: "Green Line", type: 0}],
        red_line: [red_line]]

    end

    test "groups Mattapan in with the Red line" do
      red_line = %Route{id: "Red", name: "Red", type: 1}
      mattapan_line = %Route{id: "Mattapan", name: "Red", type: 0}
      route_list = [mattapan_line, red_line]

      assert get_route_groups(route_list) == [red_line: [red_line]]

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
    options = %Options{nearby_fn: &mock_response/1}

    conn
    |> assign_query_params(%{"location" => %{"address" => address}})
    |> Site.Plugs.ServiceNearMe.call(options)
  end

  def assign_query_params(conn, params) do
    %{conn | params: params}
  end
end
