defmodule Site.TripPlanViewTest do
  use Site.ConnCase, async: true
  import Site.TripPlanView
  import Phoenix.HTML, only: [safe_to_string: 1]
  import UrlHelpers, only: [update_url: 2]
  import Site.ViewHelpers, only: [hyphenated_mode_string: 1]
  alias Site.TripPlan.{Query, ItineraryRow}
  alias TripPlan.Api.MockPlanner
  alias Routes.Route

  describe "itinerary_explanation/1" do
    @base_explanation_query %Query{from: {:error, :unknown},
                                   to: {:error, :unknown},
                                   itineraries: {:error, :unknown}}
    @date_time DateTime.from_unix!(0)

    test "returns nothing for an empty query" do
      assert @base_explanation_query |> itinerary_explanation |> IO.iodata_to_binary == ""
    end

    test "for wheelchair accessible depart_by trips, includes that in the message" do
      query = %{@base_explanation_query |
                time: {:depart_at, @date_time},
                wheelchair_accessible?: true}
      expected = "Wheelchair accessible trips shown are based on the fastest route and \
closest departure to 12:00 AM, Thursday, January 1st."
      actual = query |> itinerary_explanation |> IO.iodata_to_binary
      assert actual == expected
    end

    test "for regular arrive_by trips, includes that in the message" do
      query = %{@base_explanation_query |
                time: {:arrive_by, @date_time},
                wheelchair_accessible?: false}
      expected = "Trips shown are based on the fastest route and \
closest arrival to 12:00 AM, Thursday, January 1st."
      actual = query |> itinerary_explanation |> IO.iodata_to_binary
      assert actual == expected
    end
 end

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
      {:error, {:multiple_results, results}} = from = TripPlan.geocode("too many results")
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

  describe "stop_departure_display/1" do
    @time ~N[2017-06-27T11:43:00]

    test "returns blank when trip is available" do
      trip_row = %ItineraryRow{trip: %Schedules.Trip{}}

      assert stop_departure_display(trip_row) == :blank
    end

    test "returns formatted time when trip is not available" do
      row = %ItineraryRow{trip: nil, departure: @time}
      assert stop_departure_display(row) == {:render, "11:43A"}
    end
  end

  describe "render_stop_departure_display/1" do
    test "does not render :blank" do
      refute render_stop_departure_display(:blank)
    end

    test "renders time when given one" do
      text = {:render, "11:00A"} |> render_stop_departure_display() |> safe_to_string
      assert text =~ "11:00A"
    end
  end

  describe "bubble_params/1 for a transit row" do
    @itinerary_row %ItineraryRow{
      transit?: true,
      stop: {"Park Street", "place-park"},
      steps: ["Boylston",
              "Arlington",
              "Copley"
      ],
      route: %Route{id: "Green", name: "Green Line", type: 1}
    }

    test "builds bubble_params for each step" do
      params = bubble_params(@itinerary_row, nil)

      for {_step, param} <- params do
        assert [%Site.StopBubble.Params{
          route_id: "Green",
          route_type: 1,
          render_type: :stop,
          bubble_branch: "Green Line"
        }] = param
      end

      assert Enum.map(params, &elem(&1, 0)) == [:transfer | @itinerary_row.steps]
    end

    test "First step is not dotted when it has less than 4 intermediate steps" do
      dotted? =
        @itinerary_row
        |> bubble_params(nil)
        |> Enum.map(fn {_, [%{class: class}]} -> class end)

      assert dotted? == ["stop", "stop", "stop", "stop"]
    end

    test "First step is dotted when it has 4 or more intermediate steps" do
      dotted? =
        %{@itinerary_row | steps: ["Prudential", "Symphony", "Northeastern" | @itinerary_row.steps]}
        |> bubble_params(nil)
        |> Enum.map(fn {_, [%{class: class}]} -> class end)

      assert dotted? == ["stop", "stop dotted", "stop", "stop", "stop", "stop", "stop"]
    end
  end

  describe "bubble_params/1 for a personal row" do
    @itinerary_row %ItineraryRow{
      transit?: false,
      stop: {"Park Street", "place-park"},
      steps: ["Tremont and Winter",
              "Winter and Washington",
              "Court St. and Washington"
      ],
      route: nil
    }

    test "builds bubble params for each step" do
      params = bubble_params(@itinerary_row, 0)

      for {_step, param} <- params do
        assert [%Site.StopBubble.Params{
          route_id: nil,
          route_type: nil,
          bubble_branch: nil
        }] = param
      end

      assert Enum.map(params, &elem(&1, 0)) == [:transfer | @itinerary_row.steps]
    end

    test "all but first stop are lines" do
      [_transfer | types_and_classes] =
        @itinerary_row
        |> bubble_params(0)
        |> Enum.map(fn {_, [%{class: class, render_type: render_type}]} -> {class, render_type} end)

      assert types_and_classes == [{"line dotted", :empty}, {"line dotted", :empty}, {"line dotted", :empty}]
    end

    test "first stop is terminus for first row" do
      [{_transfer_step, [%{class: class, render_type: render_type}]} | _rest] = bubble_params(@itinerary_row, 0)

      assert class == "terminus dotted"
      assert render_type == :terminus
    end

    test "first stop is stop for a row other than the first" do
      [{_transfer_step, [%{class: class, render_type: render_type}]} | _rest] = bubble_params(@itinerary_row, 3)

      assert class == "stop dotted"
      assert render_type == :stop
    end
  end

  describe "render_steps/2" do
    @bubble_params [%Site.StopBubble.Params{
      render_type: :empty,
      class: "line dotted"
    }]
    @steps [
      {"Tremont and Winter", @bubble_params},
      {"Winter and Washington", @bubble_params},
      {"Court St. and Washington", @bubble_params}
    ]

    test "renders the provided subset of {step, bubbles}" do
      html =
        @steps
        |> render_steps("personal")
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert Enum.count(Floki.find(html, ".personal")) == 3
      assert Enum.count(Floki.find(html, ".route-branch-stop-bubble")) == 3
      names =
        html
        |> Floki.find(".itinerary-step")
        |> Enum.map(fn {_elem, _attrs, [name]} -> String.trim(name) end)
      assert names == ["Tremont and Winter", "Winter and Washington", "Court St. and Washington"]
    end
  end

  describe "format_additional_route/2" do
    test "Correctly formats Green Line route" do
      route = %Route{name: "Green Line B", id: "Green-B", direction_names: %{1 => "Eastbound"}}
      actual = route |> format_additional_route(1) |> IO.iodata_to_binary
      assert actual == "Green Line (B) Eastbound towards Park Street"
    end
  end

  describe "icon_for_route/1" do
    test "non-subway transit legs" do
      for gtfs_type <- 2..4 do
        route = %Routes.Route{
          id: "id",
          type: gtfs_type,
        }
        expected_icon_class = route
        |> Site.Components.Icons.SvgIcon.get_icon_atom
        |> hyphenated_mode_string
        icon = icon_for_route(route)
        assert safe_to_string(icon) =~ expected_icon_class
      end
    end

    test "subway transit legs" do
      for {id, type} <- [{"Red", 1}, {"Mattapan", 0}, {"Orange", 1}, {"Blue", 1}, {"Green", 0}] do
        route = %Routes.Route{
          id: id,
          type: type,
        }
        expected_icon_class = route
        |> Site.Components.Icons.SvgIcon.get_icon_atom
        |> hyphenated_mode_string
        icon = icon_for_route(route)
        assert safe_to_string(icon) =~ expected_icon_class
      end
    end
  end
end
