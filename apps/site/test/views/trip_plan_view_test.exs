defmodule Site.TripPlanViewTest do
  use Site.ConnCase, async: true
  import Site.TripPlanView
  import Phoenix.HTML, only: [safe_to_string: 1]
  import UrlHelpers, only: [update_url: 2]
  alias Site.TripPlan.{Query, ItineraryRow}
  alias TripPlan.Api.MockPlanner
  alias Routes.Route
  alias Site.PartialView.StopBubbles

  describe "rendered_location_error/3" do
    test "renders an empty string if there's no query", %{conn: conn} do
      assert "" == rendered_location_error(conn, nil, :from)
    end

    test "renders an empty string if the query has a good value for the field", %{conn: conn} do
      from = MockPlanner.random_stop()
      query = %Query{from: {:ok, from}, to: {:error, :unknown}, itineraries: {:error, :unknown}}
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

  describe "mode_class/1" do
    test "returns the icon atom if a route is present" do
      row = %ItineraryRow{route: %Route{id: "Red"}}

      assert mode_class(row) == "red-line"
    end

    test "returns 'personal' if no route is present" do
      row = %ItineraryRow{route: nil}

      assert mode_class(row) == "personal"
    end
  end

  describe "intermediate_bubble_params/2" do
    test "returns the bubble params unchanged if a route exists" do
      row = %ItineraryRow{route: %Route{id: "Red"}}
      params = %StopBubbles.Params{line_only?: false}

      assert intermediate_bubble_params(row, params) == params
    end

    test "sets line_only?: true if no route exists" do
      row = %ItineraryRow{route: nil}
      params = %StopBubbles.Params{line_only?: false}

      assert intermediate_bubble_params(row, params).line_only?
    end
  end

  describe "itinerary_steps_with_classes/1" do
    test "it gives no data-attribute to any step in a list with less than 6 steps" do
      row = %ItineraryRow{route: %Route{}, steps: ["1", "2", "3", "4", "5"]}
      assert itinerary_steps_with_classes(row) == [{"1", ""}, {"2", ""}, {"3", ""}, {"4", ""}, {"5", ""}]
    end

    test "it gives a data-attribute of before-reveal-button to the first step and
          hidden-step to the middle steps in a list with 6 or more steps" do
      row = %ItineraryRow{route: %Route{}, steps: ["1", "2", "3", "4", "5", "6"]}
      assert itinerary_steps_with_classes(row) ==
        [{"1", "data-before-reveal-button"}, {"2", "data-hidden-step"}, {"3", "data-hidden-step"}, {"4", "data-hidden-step"}, {"5", ""}, {"6", ""}]
    end

    test "it does not give the hidden-step data-attribute when the leg is personal" do
      row = %ItineraryRow{route: nil, steps: ["1", "2", "3", "4", "5", "6"]}
      assert itinerary_steps_with_classes(row) ==
        [{"1", ""}, {"2", ""}, {"3", ""}, {"4", ""}, {"5", ""}, {"6", ""}]
    end
  end

  describe "collapsable_row?/1" do
    test "is true when the length of the steps is 6 or greater" do
      row = %ItineraryRow{route: %Route{}, steps: ["1", "2", "3", "4", "5", "6"]}
      assert collapsable_row?(row)
    end

    test "is false when the length of the steps is less than 6" do
      row = %ItineraryRow{route: %Route{}, steps: ["1", "2", "3", "4", "5"]}
      refute collapsable_row?(row)
    end

    test "is false when it is a personal leg" do
      row = %ItineraryRow{route: nil, steps: ["1", "2", "3", "4", "5", "6"]}
      refute collapsable_row?(row)
    end
  end
end
