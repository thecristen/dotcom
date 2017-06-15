defmodule Site.TripPlanControllerTest do
  use Site.ConnCase, async: true

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
  end

  describe "index with params" do
    test "renders the query plan", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
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
  end
end
