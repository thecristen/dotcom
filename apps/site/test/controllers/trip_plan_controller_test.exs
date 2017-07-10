defmodule Site.TripPlanControllerTest do
  use Site.ConnCase, async: true
  alias Site.TripPlan.Query
  import Phoenix.HTML, only: [html_escape: 1, safe_to_string: 1]

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
      response = html_response(conn, 200)
      assert response =~ "Directions"
      assert response =~ "Itinerary 1"
      assert conn.assigns.requires_google_maps?
      assert %Query{} = conn.assigns.query
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
      assert %Query{} = conn.assigns.query
      assert Map.size(conn.assigns.route_map) > 0
    end

    test "each map url has a path color", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      for {map_data, static_map} <- conn.assigns.itinerary_maps do
        assert static_map =~ "color"
        for path <- map_data.paths do
          assert path.color
        end
      end
    end

    test "renders a geocoding error", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @bad_params)
      response = html_response(conn, 200)
      assert response =~ "Directions"
      assert response =~ "Did you mean?"
      assert conn.assigns.requires_google_maps?
      assert %Query{} = conn.assigns.query
    end

    test "renders a prereq error with the initial map", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, plan: %{"from" => "", "to" => ""})
      response = html_response(conn, 200)
      assert response =~ conn.assigns.initial_map_src |> html_escape |> safe_to_string
    end

    test "assigns maps for each itinerary", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert conn.assigns.itinerary_maps
      for {_map_data, static_map} <- conn.assigns.itinerary_maps do
        assert static_map =~ "https://maps.googleapis.com/maps/api/staticmap"
      end
    end

    test "assigns an ItineraryRowList for each itinerary", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert conn.assigns.itinerary_row_lists
    end

    test "assigns a list of alerts for each itinerary", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      {:ok, itineraries} = conn.assigns.query.itineraries
      assert length(itineraries) == length(conn.assigns.alerts)
    end
  end
end
