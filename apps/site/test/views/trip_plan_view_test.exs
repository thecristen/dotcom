defmodule Site.TripPlanViewTest do
  use Site.ConnCase, async: true
  import Site.TripPlanView
  import Phoenix.HTML, only: [safe_to_string: 1]
  import UrlHelpers, only: [update_url: 2]
  alias Site.TripPlan.Query
  alias TripPlan.Api.MockPlanner

  @from MockPlanner.random_stop()
  @to MockPlanner.random_stop()
  @start ~N[2017-01-01T00:00:00]
  @stop ~N[2017-01-01T23:59:59]

  describe "rendered_location_error/3" do
    test "renders an empty string if there's no query", %{conn: conn} do
      assert "" == rendered_location_error(conn, nil, :from)
    end

    test "renders an empty string if the query has a good value for the field", %{conn: conn} do
      query = %Query{from: {:ok, @from}, to: {:error, :unknown}, itineraries: {:error, :unknown}}
      assert "" == rendered_location_error(conn, query, :from)
      refute "" == rendered_location_error(conn, query, :to)
    end

    test "renders each position as a link if we have too many results", %{conn: conn} do
      {:error, {:too_many_results, results}} = from = TripPlan.geocode("too many results")
      query = %Query{
        from: from,
        to: {:error, :unknown},
        itineraries: {:error, :unknown}}
      conn = Map.put(conn, :query_params, %{})
      rendered = conn
      |> rendered_location_error(query, :from)
      |> safe_to_string
      assert rendered =~ "Did you mean?"
      for result <- results do
        assert rendered =~ result.name
        assert rendered =~ update_url(conn, %{plan: %{from: result.name}})
      end
    end
  end

  describe "leg_feature/2" do
    test "works for all kinds of transit legs" do
      for _ <- 0..10 do
        transit_leg = MockPlanner.transit_leg(@from, @to, @start, @stop)
        route_id = transit_leg.mode.route_id
        route_map = %{
          route_id => Routes.Repo.get(route_id)
        }
        assert leg_feature(transit_leg, route_map)
      end
    end

    test "works for all kinds of personal legs" do
      for _ <- 0..10 do
        personal_leg = MockPlanner.personal_leg(@from, @to, @start, @stop)
        assert leg_feature(personal_leg, %{})
      end
    end
  end

  describe "input_class/2" do
    test "returns trip-plan-current-location if the relevant lat and lng are set" do
      from_current_location = %{"from_latitude" => "42.349159", "from_longitude" => "-71.0655084"}
      assert location_input_class(from_current_location, :from) == "trip-plan-current-location"
      assert location_input_class(from_current_location, :to) == ""
    end

    test "returns the empty string if only one of latitude or longitude is set" do
      params = %{"from_latitude" => "42.349159", "to_latitude" => ""}
      assert location_input_class(params, :from) == ""
    end

    test "returns the empty string if both lat and lng are blank" do
      params = %{"from_latitude" => "", "to_latitude" => ""}
      assert location_input_class(params, :from) == ""
    end
  end
end
