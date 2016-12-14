defmodule Site.Plugs.TransitNearMeTest do
  use Site.ConnCase

  import Site.Plugs.TransitNearMe

  alias Site.Plugs.TransitNearMe.Options
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
      |> bypass_through(Site.Router, :browser)
      |> get("/")
      |> assign_query_params(%{"location" => %{"address" => @address}})
      |> call(options)

      assert :stops_with_routes in Map.keys conn.assigns
      assert :address in Map.keys conn.assigns
      assert get_flash(conn) == %{}
    end

    test "assigns no stops and empty address if none is provided", %{conn: conn} do
      conn = conn
      |> assign_query_params(%{})
      |> bypass_through(Site.Router, :browser)
      |> get("/")
      |> call(%Options{})

      assert conn.assigns.stops_with_routes == []
      assert conn.assigns.address == ""
      assert get_flash(conn)["info"] =~ "No address"
    end

    test "flashes message if no results are returned", %{conn: conn} do
      options = %Options{nearby_fn: fn _ -> [] end}

      conn = conn
      |> bypass_through(Site.Router, :browser)
      |> get("/")
      |> assign_query_params(%{"location" => %{"address" => @address}})
      |> call(options)

      assert conn.assigns.stops_with_routes == []
      assert conn.assigns.address == "10 Park Plaza, Boston, MA 02116, USA"
      assert get_flash(conn)["info"] =~ "doesn't seem to be any stations"
    end

    test "can take a lat/long as query parameters", %{conn: conn} do
      options = %Options{nearby_fn: &mock_response/1}
      lat = 42.3515322
      lng = -71.0668452

      conn = conn
      |> bypass_through(Site.Router, :browser)
      |> get("/")
      |> assign_query_params(%{"latitude" => "#{lat}", "longitude" => "#{lng}"})
      |> call(options)

      assert :stops_with_routes in Map.keys conn.assigns
      assert :address in Map.keys conn.assigns
      assert get_flash(conn) == %{}
    end
  end

  describe "init/1" do
    test "it returns a default options struct" do
      assert init([]) == %Options{}
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

  describe "put_flash_if_error/2" do
    test "does nothing if there are stops_with_routes", %{conn: conn} do
      conn = conn
      |> assign(:stops_with_routes, [{%Stops.Stop{}, []}])
      |> bypass_through(Site.Router, :browser)
      |> get("/")
      |> flash_if_error

      assert get_flash(conn) == %{}
    end

    test "shows message if there's no address", %{conn: conn} do
      conn = conn
      |> assign(:address, "")
      |> bypass_through(Site.Router, :browser)
      |> get("/")
      |> flash_if_error

      assert get_flash(conn)["info"] =~ "No address"
    end

    test "shows message if there's no stops_with_routes", %{conn: conn} do
      conn = conn
      |> assign(:stops_with_routes, [])
      |> bypass_through(Site.Router, :browser)
      |> get("/")
      |> flash_if_error

      assert get_flash(conn)["info"] =~ "There doesn't seem to be any stations"
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
    |> Site.Plugs.TransitNearMe.call(options)
  end

  def assign_query_params(conn, params) do
    %{conn | params: params}
  end
end
