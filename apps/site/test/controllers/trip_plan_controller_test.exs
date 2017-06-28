defmodule Site.TripPlanControllerTest do
  use Site.ConnCase, async: true
  alias Site.TripPlanController.TripPlanMap

  @good_params %{
    "plan" => %{"from" => "from address",
                "to" => "to address"}
  }
  @bad_params %{
    "plan" => %{"from" => "no results",
                "to" => "too many results"}
  }

  describe "index without params" do
    test "renders index.html", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index)
      assert html_response(conn, 200) =~ "Directions"
      assert conn.assigns.requires_google_maps?
    end

    test "assigns initial_map_src", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index)
      assert conn.assigns.initial_map_src
    end
  end

  describe "index with params" do
    test "renders the query plan", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert html_response(conn, 200) =~ "Directions"
      assert conn.assigns.requires_google_maps?
      assert %TripPlan.Query{} = conn.assigns.query
      assert Map.size(conn.assigns.route_map) > 0
    end

    test "uses current location to render a query plan", %{conn: conn} do
      params = %{
        "plan" => %{"from" => "Current Location",
                    "from_latitude" => "42.3428",
                    "from_longitude" => "-71.0857",
                    "to" => "to address",
                    "to_latitude" => "",
                    "to_longitude" => ""
                   }
      }
      conn = get conn, trip_plan_path(conn, :index, params)

      assert html_response(conn, 200) =~ "Directions"
      assert conn.assigns.requires_google_maps?
      assert %TripPlan.Query{} = conn.assigns.query
      assert Map.size(conn.assigns.route_map) > 0
    end

    test "renders a geocoding error", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @bad_params)
      response = html_response(conn, 200)
      assert response =~ "Directions"
      assert response =~ "Too many results returned"
      assert conn.assigns.requires_google_maps?
      assert %TripPlan.Query{} = conn.assigns.query
    end

    test "assigns maps for each itinerary", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert conn.assigns.itinerary_maps
      {:ok, itineraries} = conn.assigns.query.itineraries
      for {itinerary, itinerary_map} <- Enum.zip(itineraries, conn.assigns.itinerary_maps) do
        assert itinerary_map == TripPlanMap.itinerary_map(itinerary)
      end
    end
  end
end
