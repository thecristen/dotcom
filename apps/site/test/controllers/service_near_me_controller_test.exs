defmodule Site.ServiceNearMeControllerTest do
  use Site.ConnCase

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
  end

  def mock_response(_) do
    @stop_ids
    |> Enum.map(&Stops.Repo.get/1)
  end

  def search_near_office(conn) do
    conn
    |> put_private(:nearby_stops, &mock_response/1)
    |> get(service_near_me_path(conn, :index, %{"location" => %{"address" => @address}}))
  end

  def get_encoded_query(conn, query) do
    %{query_string: query_string} = get conn, service_near_me_path(conn, :index, query)
    query_string
    |> String.split("=")
    |> List.last
  end

  def get_random_location do
    get_lat_lng
    |> GoogleMAps.Geocode.geocode
    |> do_get_random_location
  end

  def get_lat_lng do
    lat = @lat
    |> tiny_move
    |> Float.to_string
    lng = @lng
    |> tiny_move
    |> Kernel.-(:rand.uniform * :rand.uniform)
    |> Float.to_string
    "#{lat},#{lng}"
  end

  def tiny_move(coord) do
    :rand.uniform
    |> Kernel.*(0.0001)
    |> Kernel.+(coord)
  end

  defp do_get_random_location({:ok, [address | _]}), do: address
end
