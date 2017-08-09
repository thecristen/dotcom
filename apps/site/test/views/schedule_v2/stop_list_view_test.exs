defmodule Site.StopListViewTest do
  use Site.ConnCase, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ScheduleV2View.StopList
  alias Stops.RouteStop
  alias Routes.Route
  alias Schedules.Departures
  alias Site.StopBubble

  @trip %Schedules.Trip{name: "101", headsign: "Headsign", direction_id: 0, id: "1"}
  @stop %Stops.Stop{id: "stop-id", name: "Stop Name"}
  @route %Routes.Route{type: 3, id: "1"}
  @prediction %Predictions.Prediction{departing?: true, direction_id: 0, status: "On Time", trip: @trip}
  @schedule %Schedules.Schedule{
    route: @route,
    trip: @trip,
    stop: @stop
  }
  @vehicle %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: @route.id}
  @predicted_schedule %PredictedSchedule{prediction: @prediction, schedule: @schedule}
  @trip_info %TripInfo{
    route: @route,
    vehicle: @vehicle,
    vehicle_stop_name: @stop.name,
    times: [@predicted_schedule],
  }
  @assigns %{
    bubbles: [{nil, :terminus}],
    stop: %RouteStop{branch: nil, id: "stop"},
    route: %Route{id: "route_id", type: 1},
    direction_id: 1,
    conn: "conn",
    add_expand_link?: false,
    branch_names: ["branch"],
    vehicle_tooltip: %VehicleTooltip{vehicle: %Vehicles.Vehicle{route_id: "route_id"}},
    row_content_template: "_line_page_stop_info.html"
  }

  describe "stop_bubble_row_params/2" do
    test "flattens the assigns into the map needed for the stop bubbles for a particular row" do
      params = stop_bubble_row_params(@assigns)

      assert [%StopBubble.Params{
        render_type: :terminus,
        class: "terminus",
        route_id: nil,
        route_type: 1,
        direction_id: 1,
        vehicle_tooltip: %VehicleTooltip{},
        merge_indent: nil,
        show_line?: true
      }] = params
    end

    test "sets to render_type to :empty and the class to :line when a :line bubble is passed in" do
      assigns = %{@assigns | bubbles: [{"branch", :line}]}

      [params] = stop_bubble_row_params(assigns, true)

      assert params.render_type == :empty
      assert params.class == "line"
      assert params.show_line?
    end

    test "sets the render_type to :empty and the class to :merge on the second merge bubble" do
      assigns = %{@assigns | bubbles: [{"branch", :merge}, {"branch", :merge}]}

      params = stop_bubble_row_params(assigns, true)

      assert [%StopBubble.Params{render_type: :merge, class: "merge"},
              %StopBubble.Params{render_type: :empty, class: "merge dotted"}
             ] = params
    end

    test "does not provide a vehicle_tooltip is no vehicle_tooltip is present" do
      assigns = %{@assigns | vehicle_tooltip: nil}

      [params] = stop_bubble_row_params(assigns, true)

      refute params.vehicle_tooltip
    end

    test "only provides a tooltip for the bubble whose branch matches the vehicle's route_id on the green line" do
      assigns = %{@assigns |
        bubbles: [{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}],
        route: %Route{id: "Green"},
        vehicle_tooltip: %VehicleTooltip{vehicle: %Vehicles.Vehicle{route_id: "Green-D"}}}

      tooltips =
        assigns
        |> stop_bubble_row_params
        |> Enum.map(&(&1.vehicle_tooltip))

      assert [nil, nil, %VehicleTooltip{}, nil] = tooltips
    end

    test "does not provide a vehicle_tooltip if the render_type is :line" do
      assigns = %{@assigns | bubbles: [{"branch", :line}]}

      [params] = stop_bubble_row_params(assigns)

      refute params.vehicle_tooltip
    end

    test "sets show_line? to false if the render_type is :empty" do
      assigns = %{@assigns | bubbles: [{"branch", :empty}]}

      [params] = stop_bubble_row_params(assigns, true)

      assert params.render_type == :empty
      assert params.class == "empty"
      refute params.show_line?
    end

    test "sets show_line? false if the render_type is :terminus and the stop is not the first stop" do
      assigns = %{@assigns | bubbles: [{"branch", :terminus}]}

      [params] = stop_bubble_row_params(assigns, false)

      refute params.show_line?
    end

    test "sets content to the letter of the green line branch if the route is green" do
      assigns = %{@assigns | route: %Route{id: "Green", type: 1}, bubbles: [{"Green-B", :stop}]}

      [params] = stop_bubble_row_params(assigns, false)

      assert params.content == "B"
    end

    test "sets content to the empty string for any other route id" do
      [params] = stop_bubble_row_params(@assigns, false)

      assert params.content == ""
    end
  end

  describe "Green Line bubble params" do
    test "at copley when direction is 0" do
      assigns = %{@assigns | bubbles: Enum.map(["B", "C", "D", "E"], & {"Green-" <> &1, :stop}),
                             direction_id: 0,
                             route: %Route{id: "Green", type: 0},
                             stop: %RouteStop{id: "place-coecl", branch: nil}}
      assert [b_line, c_line, d_line, e_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
      assert e_line.class == "stop dotted"
    end

    test "at copley when direction is 1" do
      assigns = %{@assigns | bubbles: Enum.map(["B", "C", "D", "E"], & {"Green-" <> &1, :stop}),
                             direction_id: 1,
                             route: %Route{id: "Green", type: 0},
                             stop: %RouteStop{id: "place-coecl", branch: nil}}
      assert [b_line, c_line, d_line, e_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
      assert e_line.class == "stop"
    end

    test "for E line branch stops in either direction" do
      assigns = %{@assigns | bubbles: Enum.map(["B", "C", "D", "E"], & {"Green-" <> &1, :stop}),
                             direction_id: 0,
                             route: %Route{id: "Green", type: 0},
                             stop: %RouteStop{id: "place-prmnl", branch: "Green-E"}}

      assert [b_line, c_line, d_line, e_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
      assert e_line.class == "stop dotted"

      assert [b_line_1, c_line_1, d_line_1, e_line_1] = stop_bubble_row_params(%{assigns | direction_id: 1})
      assert b_line_1.class == "stop"
      assert c_line_1.class == "stop"
      assert d_line_1.class == "stop"
      assert e_line_1.class == "stop dotted"
    end

    test "all kenmore bubbles are dotted when direction_id is 0" do
      assigns = %{@assigns | bubbles: Enum.map(["B", "C", "D"], & {"Green-" <> &1, :stop}),
                             direction_id: 0,
                             route: %Route{id: "Green", type: 0},
                             stop: %RouteStop{id: "place-kencl", branch: nil}}
      assert [b_line, c_line, d_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop dotted"
      assert c_line.class == "stop dotted"
      assert d_line.class == "stop dotted"
    end

    test "all kenmore bubbles are solid when direction_id is 1" do
      assigns = %{@assigns | bubbles: Enum.map(["B", "C", "D"], & {"Green-" <> &1, :stop}),
                             direction_id: 1,
                             route: %Route{id: "Green", type: 0},
                             stop: %RouteStop{id: "place-kencl", branch: nil}}
      assert [b_line, c_line, d_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
    end

    test "stops before copley do not have dotted class" do
      assigns = %{@assigns | bubbles: Enum.map(["B", "C", "D", "E"], & {"Green-" <> &1, :stop}),
                             direction_id: 0,
                             route: %Route{id: "Green", type: 0},
                             stop: %RouteStop{id: "place-pktrm", branch: nil}}
      assert [b_line, c_line, d_line, e_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
      assert e_line.class == "stop"

      assert [b_line_1, c_line_1, d_line_1, e_line_1] = stop_bubble_row_params(%{assigns | direction_id: 1})
      assert b_line_1.class == "stop"
      assert c_line_1.class == "stop"
      assert d_line_1.class == "stop"
      assert e_line_1.class == "stop"
    end

    test "branch stops are all dotted" do
      assigns = %{@assigns | bubbles: [{"Green-B", :stop}, {"Green-C", :stop}],
                             direction_id: 0,
                             route: %Route{id: "Green", type: 0},
                             stop: %RouteStop{id: "place-clmnl", branch: "Green-C"}}

      assert [b_line, c_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop dotted"
      assert c_line.class == "stop dotted"

      assert [b_line, c_line] = stop_bubble_row_params(%{assigns | direction_id: 1})
      assert b_line.class == "stop dotted"
      assert c_line.class == "stop dotted"
    end
  end

  describe "non-Green bubble params" do
    test "stop bubbles are never dotted on non-Green, non-branch stops" do
      assigns = %{@assigns | bubbles: [{nil, :stop}],
                            route: %Route{id: "Red", type: 1},
                            stop: %RouteStop{id: "place-pktrm", branch: nil}}
      assert [params] = stop_bubble_row_params(assigns)
      assert params.class == "stop"
    end

    test "stop bubbles are always dotted on non-Green branch stops" do
      assigns = %{@assigns | bubbles: [{"Ashmont", :stop}, {"Braintree", :stop}],
                            route: %Route{id: "Red", type: 1},
                            stop: %RouteStop{id: "place-nqncy", branch: "Braintree"}}
      assert [ashmont, braintree] = stop_bubble_row_params(assigns)
      assert ashmont.class == "stop dotted"
      assert braintree.class == "stop dotted"
    end
  end

  describe "merge stop bubble params" do
    test "both bubbles have dotted class when direction_id is 0" do
      assigns = %{@assigns | bubbles: [{"Ashmont", :merge}, {"Braintree", :merge}],
                direction_id: 0,
                route: %Route{id: "Red", type: 1},
                stop: %RouteStop{id: "place-jfk", branch: nil}}
      assert [ashmont, braintree] = stop_bubble_row_params(assigns)
      assert ashmont.class == "merge dotted"
      assert braintree.class == "merge dotted"
    end

    test "only second bubble has dotted class when direction_id is 1" do
      assigns = %{@assigns | bubbles: [{"Ashmont", :merge}, {"Braintree", :merge}],
                route: %Route{id: "Red", type: 1},
                stop: %RouteStop{id: "place-jfk", branch: nil}}
      assert [ashmont, braintree] = stop_bubble_row_params(assigns)
      assert ashmont.class == "merge"
      assert braintree.class == "merge dotted"
    end
  end

  describe "rendering stop list rows" do
    @trunk [
      {[{nil, :terminus}], %RouteStop{name: "Broadway", id: "broadway", branch: nil}},
      {[{nil, :stop}], %RouteStop{name: "Andrew", id: "andrew", branch: nil}},
      {[{nil, :merge}], %RouteStop{name: "JFK/Umass", id: "jfk-umass", branch: nil}}
    ]
    @braintree [
      {[{"Ashmont", :line},
        {"Braintree", :stop}],
        %RouteStop{name: "North Quincy", id: "north-quincy", branch: "Braintree"}},
      {[{"Ashmont", :line},
        {"Braintree", :terminus}],
        %RouteStop{name: "Wollaston", id: "wollaston", branch: "Braintree"}},
    ]
    @ashmont [
      {[{"Ashmont", :stop},
        {"Braintree", :empty}],
        %RouteStop{name: "Savin Hill", id: "savin-hill", branch: "Ashmont"}},
      {[{"Ashmont", :terminus},
        {"Braintree", :empty}],
        %RouteStop{name: "Fields Corner", id: "fields-corner", branch: "Ashmont"}}
    ]
    @assigns %{
      all_stops: @trunk ++ @braintree ++ @ashmont,
      route: %Route{id: "Red", name: "Red Line", type: 1},
      direction_id: 0,
      vehicle_tooltips: %{}
    }

    test "splits the stops up into groups based on the branch" do
      stops =
        @assigns.all_stops
        |> chunk_branches()
        |> Enum.map(fn chunk ->
          Enum.map(chunk, fn {_bubbles, %RouteStop{name: name}} -> name end)
        end)

      assert stops == [["Broadway", "Andrew", "JFK/Umass"],
                       ["North Quincy", "Wollaston"],
                       ["Savin Hill", "Fields Corner"]
                      ]
    end

    test "extracts the last row as the expand row for direction-id = 0" do
       expected = {List.last(@braintree), -1, Enum.take(@braintree, 1)}
      assert separate_collapsible_rows(@braintree, 0) == expected
    end

    test "extracts the first row as the expand row for direction-id = 1" do
      expected = {List.first(@braintree), 0, Enum.drop(@braintree, 1)}
      assert separate_collapsible_rows(@braintree, 1) == expected
    end

    test "renders a stop row", %{conn: conn} do
      [row | _] = @trunk

      html =
        row
        |> render_row(Map.put(@assigns, :conn, conn))
        |> safe_to_string

      assert html =~ "route-branch-stop-bubble"
    end

    test "recombines expand and collapsible rows when branch is nil", %{conn: conn} do
      separated_rows =
        separate_collapsible_rows(@trunk, 0)

      html =
        separated_rows
        |> merge_rows(Map.put(@assigns, :conn, conn))
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      refute html =~ "id =\"branch-braintree\""
      refute html =~ "id =\"branch-ashmont\""
      refute html =~ "class=\"collapse\""

      names =
        html
        |> Floki.find(".route-branch-stop-name")
        |> Enum.map(fn {_elem, _attrs, [name]} -> String.trim(name) end)

      assert names == ["Broadway", "Andrew", "JFK/​Umass"]
    end

    test "inserts a collapse target div and an expand link when the branch is not nil", %{conn: conn} do
      separated_rows =
        separate_collapsible_rows(@braintree, 0)

      html =
        separated_rows
        |> merge_rows(Map.put(@assigns, :conn, conn))
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert Enum.count(Floki.find(html, ".collapse")) == 1
      assert Enum.count(Floki.find(html, "#branch-braintree")) == 1
      assert Enum.count(Floki.find(html, "#branch-ashmont")) == 0

      names =
        html
        |> Floki.find(".route-branch-stop-name")
        |> Enum.map(fn {_elem, _attrs, [name]} -> String.trim(name) end)

      assert names == ["North Quincy", "Wollaston"]
    end
  end

  describe "display_departure_range/1" do
    test "with no times, returns No Service" do
      result = display_departure_range(%Departures{first_departure: nil, last_departure: nil})
      assert result == "No Service"
    end

    test "with times, displays them formatted" do
      result = %Departures{
        first_departure: ~N[2017-02-27 06:15:00],
        last_departure: ~N[2017-02-28 01:04:00]
      }
      |> display_departure_range
      |> IO.iodata_to_binary

      assert result == "06:15A-01:04A"
    end
  end

  describe "display_map_link?/1" do
    test "is true for subway and ferry" do
      assert display_map_link?(4) == true
    end

    test "is false for subway, bus and commuter rail" do
      assert display_map_link?(0) == false
      assert display_map_link?(3) == false
      assert display_map_link?(2) == false
    end
  end

  describe "trip_link/4" do
    test "trip link for non-matching trip", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, false, "2") == "/?trip=2#2"
    end

    test "trip link for matching, un-chosen stop", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, false, "1") == "/?trip=1#1"
    end

    test "trip link for matching, chosen stop", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, true, "1") == "/?trip=#1"
    end
  end
end
