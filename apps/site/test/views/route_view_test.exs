defmodule Site.RouteViewTest do
  use Site.ConnCase, async: true
  import Site.RouteView
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "route_row/3" do
    test "returns route name with bubble and featured icons", %{conn: conn} do
      row =
        conn
        |> assign(:route, %Routes.Route{id: "Red", name: "Red Line"})
        |> route_row(%Stops.Stop{id: "stop", name: "Stop Name"}, [:bus, :subway], false)
        |> safe_to_string
      assert row =~ "Stop Name"
      assert row =~ "stop-bubble"
      assert row =~ "bus"
      assert row =~ "subway"
    end
  end

  describe "route_row/3 for commuter rail" do
    test "returns route name with bubble, featured icons and zone", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{id: "CR-Providence", name: "Stoughton"})
      |> assign(:zones, %{"stop" => "A"})

      row = route_row(conn, %Stops.Stop{id: "stop", name: "Stop Name"}, [:bus, :subway], false)
      |> safe_to_string

      assert row =~ "Stop Name"
      assert row =~ "stop-bubble"
      assert row =~ "bus"
      assert row =~ "subway"
      assert row =~ "Zone A"
    end
  end

  describe "hide_branch_link/2" do
    test "generates a link to hide the given branch", %{conn: conn} do
      link = conn |> get("/", expanded: "braintree") |> hide_branch_link("Braintree") |> safe_to_string

      assert link =~ "Hide Braintree Branch"
      refute link =~ "?expanded=braintree"
    end
  end

  describe "view_branch_link/3" do
    test "generates a link to view the given branch", %{conn: conn} do
      link = conn |> fetch_query_params |> view_branch_link("braintree", "Braintree") |> safe_to_string

      assert link =~ "View Braintree Branch"
      assert link =~ "?expanded=braintree"
    end
  end

  describe "display_collapsed?/6" do
    @stops_on_routes GreenLine.stops_on_routes(0)

    test "if the line status is :line, returns true" do
      assert display_collapsed?("", "", "", :line, "", @stops_on_routes)
    end

    test "if the route line is the same as the branch to be expanded/collapsed and isn't already expanded returns true" do
      assert display_collapsed?("Green-C", "Green-B", "", :empty, "Green-B", @stops_on_routes)
    end

    test "if the next row to render is an expand/collapse button and the route line is expanded, returns false" do
      refute display_collapsed?(
        "Green-C",
        "Green-B",
        {:expand, "place-coecl", "Green-C"},
        :empty,
        "Green-E",
        @stops_on_routes
      )
    end

    test "otherwise if the next row is an expand/collapse button returns true" do
      assert display_collapsed?("Green-B", "Green-C", {:expand, "", "Green-D"}, :empty, "Green-E", @stops_on_routes)
    end

    test "if the next stop isn't on the line's route returns true" do
      assert display_collapsed?("Green-D", "Green-C", %Stops.Stop{id: "place-fenwy"}, :empty, nil, @stops_on_routes)
    end

    test "otherwise returns false" do
      refute display_collapsed?("Green-D", "Green-D", %Stops.Stop{id: "place-river"}, :empty, "Green-D", @stops_on_routes)
    end
  end
end
