defmodule Site.StopBubblesViewTest do
  use Site.ConnCase, async: true

  import Site.PartialView.StopBubbles, only: [stop_bubble_content: 2,
                                             stop_bubble_line_type: 3,
                                             stop_bubble_location_display: 3]
  alias Site.PartialView.StopBubbles.Params
  import Phoenix.HTML, only: [safe_to_string: 1]

  @vehicle_tooltip %VehicleTooltip{
    prediction: %Predictions.Prediction{departing?: true, direction_id: 0, status: "On Time"},
    vehicle: %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: "Orange"},
    route: %Routes.Route{type: 2},
    trip: %Schedules.Trip{name: "101", headsign: "Headsign"},
    stop_name: "South Station"
  }
  @terminus_class "stop-bubble-terminus"
  @line_class "route-branch-stop-bubble-line "
  @solid_line @line_class <> "solid"
  @dotted_line @line_class <> "dotted"
  @direction_class %{0 => " direction-0", 1 => " direction-1"}
  @terminus_line_type %{0 => @solid_line <> @direction_class[0], 1 => ""}
  @stop_class "stop-bubble-stop"
  @normal_stop_classes {@stop_class, @solid_line <> @direction_class[0]}
  @indent_start_class "route-branch-indent-start"
  @normal_assigns %Params{expanded: nil, stop_number: 5, stop_branch: nil, stop_id: "stop", route_id: "route",
                    route_type: 1, line_only?: false, vehicle_tooltip: nil, direction_id: 0}
  @green_assigns %Params{
                   branch_names: ["Green-B", "Green-C", "Green-D", "Green-E"],
                   bubble_index: nil,
                   bubbles: [],
                   direction_id: 0,
                   expanded: nil,
                   route_id: "Green",
                   route_type: 1,
                   stop_id: nil,
                   stop_branch: nil,
                   stop_number: nil
                 }

  describe "stop_bubble_location_display/3" do
    test "when vehicle is not at stop and stop is not a terminus, returns an empty circle" do
      rendered = safe_to_string(stop_bubble_location_display(nil, {nil, 1}, false))
      assert rendered =~ "stop-bubble-stop"
      assert rendered =~ "svg"
    end

    test "when vehicle is not at stop and stop is a terminus, returns a filled circle" do
      rendered = safe_to_string(stop_bubble_location_display(nil, {nil, 1}, true))
      assert rendered =~ "stop-bubble-terminus"
      assert rendered =~ "svg"
    end

    test "given a vehicle and the subway route_type, returns the icon for the subway" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, {"Orange", 1}, false))
      assert rendered =~ "vehicle-bubble"
    end

    test "given a vehicle and the bus route_type, returns the icon for the bus" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, {"Orange", 3}, false))
      assert rendered =~ "vehicle-bubble"
    end

    test "Does not show vehicle icon when vehicle is on a different route" do
      rendered = safe_to_string(stop_bubble_location_display(@vehicle_tooltip, {"Blue", 3}, false))
      refute rendered =~ "vehicle-bubble"
    end
  end

  describe "stop_bubble_content" do
    test "returns a bubble with a vehicle and tool tip" do
      vehicle_tooltip = %VehicleTooltip{
        prediction: %Predictions.Prediction{departing?: true, direction_id: 0, status: "On Time"},
        vehicle: %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: "route"},
        route: %Routes.Route{type: 2},
        trip: %Schedules.Trip{name: "101", headsign: "Headsign"},
        stop_name: "South Station"
      }
      assigns = %Params{expanded: nil, stop_number: 0, stop_branch: nil,
                  route_type: 1, route_id: "route", line_only?: false,
                  vehicle_tooltip: vehicle_tooltip, direction_id: 0}
      content = render_stop_bubble_content(assigns, {nil, :terminus})
      assert content =~ "train 101 has arrived at South Station"
      assert content =~ "vehicle-bubble"
    end

    test "returns a terminus bubble and a solid line for the first terminus" do
      assigns = %{@normal_assigns | stop_number: 0}
      assert stop_bubble_classes(assigns, {nil, :terminus}) == {@terminus_class, @solid_line <> @direction_class[0]}
      refute render_stop_bubble_content(assigns, {nil, :terminus}) =~ @indent_start_class
    end

    test "returns only a terminus bubble for the last terminus" do
      assert stop_bubble_classes(@normal_assigns, {nil, :terminus}) == {@terminus_class, ""}
      refute render_stop_bubble_content(@normal_assigns, {nil, :terminus}) =~ @indent_start_class
    end

    test "returns a terminus bubble and a dotted line the first teminus on a branch" do
      assigns = %{@normal_assigns | stop_number: 0, stop_branch: "branch"}
      assert stop_bubble_classes(assigns, {"branch", :terminus}) == {@terminus_class, @dotted_line <> @direction_class[0]}
      refute render_stop_bubble_content(assigns, {"branch", :terminus}) =~ @indent_start_class
    end

    test "returns a terminus bubble for the last teminus on a branch" do
      assigns = %{@normal_assigns | stop_branch: "branch"}
      assert stop_bubble_classes(assigns, {"branch", :terminus}) == {@terminus_class, ""}
      refute render_stop_bubble_content(assigns, {"branch", :terminus}) =~ @indent_start_class
    end

    test "returns a stop bubble and a solid line for an unbranched stop" do
      assert stop_bubble_classes(@normal_assigns, {nil, :stop}) == @normal_stop_classes
      refute render_stop_bubble_content(@normal_assigns, {nil, :stop}) =~ @indent_start_class
    end

    test "returns a stop bubble and a solid line for a stop on an expanded branch" do
      assigns = %{@normal_assigns | stop_branch: "branch",  expanded: "branch"}
      assert stop_bubble_classes(assigns, {"branch", :stop}) == @normal_stop_classes
      refute render_stop_bubble_content(assigns, {"branch", :stop}) =~ @indent_start_class
    end

    test "returns only a dotted line if the stop is not on the branch and the branch is collapsed" do
      assigns = %{@normal_assigns | stop_branch: "branch"}
      assert stop_bubble_line_type(:line, "other branch", assigns) == :dotted
      assert stop_bubble_classes(assigns, {"other branch", :line}) == {"", @dotted_line <> @direction_class[0]}
      refute render_stop_bubble_content(assigns, {"other branch", :line}) =~ @indent_start_class
    end

    test "returns only a solid line if the stop is not on the branch and the branch is expanded" do
      assigns = %Params{expanded: "branch", stop_number: 4, stop_branch: "other branch",
                  route_type: 0, route_id: "route", line_only?: false,
                  direction_id: 0}
      assert stop_bubble_classes(assigns, {"branch", :line}) == {"", @solid_line <> @direction_class[0]}
      refute render_stop_bubble_content(assigns, {"branch", :line}) =~ @indent_start_class
    end

    test "returns a stop bubble and a dotted line for the first merge stop in direction 0" do
      assigns = %Params{expanded: nil, stop_number: 4, stop_branch: "other branch",
                  route_type: 0, route_id: "route", line_only?: false, vehicle_tooltip: nil,
                  bubble_index: 0, direction_id: 0}
      assert stop_bubble_classes(assigns, {"branch", :merge}) == {@stop_class, @dotted_line <> @direction_class[0]}
      refute render_stop_bubble_content(assigns, {"branch", :merge}) =~ @indent_start_class
    end

    test "returns a spacer and a dotted route-branch-indent-start div for the second merge stop in direction 0" do
      assigns = %Params{expanded: nil,
                        stop_number: 4,
                        stop_branch: "other branch",
                        route_id: "route",
                        line_only?: false,
                        vehicle_tooltip: nil,
                        bubble_index: 1,
                        direction_id: 0}
      assert stop_bubble_classes(assigns, {"branch", :merge}) ==
        {"merge-stop-spacer", @indent_start_class <> " dotted", @dotted_line <> @direction_class[0]}
      assert render_stop_bubble_content(assigns, {"branch", :merge}) =~ @indent_start_class
    end

    test "returns a stop bubble and a solid line for the first merge stop in direction 1" do
      assigns = %Params{expanded: nil, stop_number: 4, route_id: "route", route_type: 0,
                  line_only?: false, vehicle_tooltip: nil,
                  bubble_index: 0, direction_id: 1}
      assert stop_bubble_classes(assigns, {"branch", :merge}) == {@stop_class, @solid_line <> @direction_class[1]}
      refute render_stop_bubble_content(assigns, {"branch", :merge}) =~ @indent_start_class
    end

    test "returns a dotted line and a dotted route-branch-indent-start div for the second merge stop in direction 1" do
      assigns = %Params{expanded: nil,
                        stop_number: 4,
                        stop_branch: "other branch",
                        route_id: "route",
                        line_only?: false,
                        vehicle_tooltip: nil,
                        bubble_index: 1,
                        direction_id: 1}
      assert stop_bubble_classes(assigns, {"branch", :merge}) ==
        {@dotted_line <> @direction_class[1], @indent_start_class <> " dotted"}
      assert render_stop_bubble_content(assigns, {"branch", :merge}) =~ @indent_start_class
    end

    test "returns a dotted line for walking directions stops" do
      assigns = %Params{
        stop_branch: nil,
        route_id: nil,
        route_type: nil,
        stop_id: nil
      }

      assert stop_bubble_classes(assigns, {nil, :stop}) ==
        {@stop_class, @dotted_line <> @direction_class[0]}
    end

    test "returns a dotted line for walking directions start terminus" do
      assigns = %Params{
        stop_branch: nil,
        route_id: nil,
        route_type: nil,
        stop_id: nil
      }

      assert stop_bubble_classes(assigns, {nil, :terminus}) ==
        {@terminus_class, @dotted_line <> @direction_class[0]}
    end
  end

  describe "green line stop_bubble_content" do
    test "lechmere" do
      westbound = %{@green_assigns | stop_id: "place-lech"}
      for direction <- [0, 1] do
        for {letter, index} <- Enum.with_index(["B", "C", "D"]) do
          branch = "Green-" <> letter
          assert stop_bubble_classes(%{westbound | bubble_index: index,
                                                   direction_id: direction}, {branch, :empty}) == {"", ""}
        end
      end
      assert stop_bubble_classes(%{westbound | bubble_index: 3}, {"Green-E", :terminus}) ==
        {@terminus_class, @solid_line <> @direction_class[0]}
      assert stop_bubble_classes(%{westbound | bubble_index: 3,
                                               direction_id: 1}, {"Green-E", :terminus}) == {@terminus_class, ""}
    end

    test "science park" do
      for direction <- [0, 1] do
        assigns = %{@green_assigns | stop_id: "place-spmnl", direction_id: direction}
        for {letter, index} <- Enum.with_index(["B", "C", "D"]) do
          branch = "Green-" <> letter
          assert stop_bubble_classes(%{assigns | bubble_index: index}, {branch, :empty}) == {"", ""}
        end
        assert stop_bubble_classes(%{assigns | bubble_index: 3}, {"Green-E", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
      end
    end

    test "north station" do
      for direction <- [0, 1] do
        assigns = %{@green_assigns | stop_id: "place-north", direction_id: direction}
        assert stop_bubble_classes(%{assigns | bubble_index: 0}, {"Green-B", :empty}) == {"", ""}
        assert stop_bubble_classes(%{assigns | bubble_index: 1}, {"Green-C", :terminus}) ==
          {@terminus_class, @terminus_line_type[direction]}
        assert stop_bubble_classes(%{assigns | bubble_index: 2}, {"Green-D", :empty}) == {"", ""}
        assert stop_bubble_classes(%{assigns | bubble_index: 3}, {"Green-E", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
      end
    end

    test "government center" do
      for direction <- [0, 1] do
        assigns = %{@green_assigns | stop_id: "place-gover", direction_id: direction}
        assert stop_bubble_classes(%{assigns | bubble_index: 0}, {"Green-B", :empty}) == {"", ""}
        assert stop_bubble_classes(%{assigns | bubble_index: 1}, {"Green-C", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
        assert stop_bubble_classes(%{assigns | bubble_index: 2}, {"Green-D", :terminus}) ==
          {@terminus_class, @terminus_line_type[direction]}
        assert stop_bubble_classes(%{assigns | bubble_index: 3}, {"Green-E", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
      end
    end

    test "park st" do
      for direction <- [0, 1] do
        assigns = %{@green_assigns | stop_id: "place-pktrm", direction_id: direction}
        assert stop_bubble_classes(%{assigns | bubble_index: 0}, {"Green-B", :terminus}) ==
          {@terminus_class, @terminus_line_type[direction]}
        assert stop_bubble_classes(%{assigns | bubble_index: 1}, {"Green-C", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
        assert stop_bubble_classes(%{assigns | bubble_index: 2}, {"Green-D", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
        assert stop_bubble_classes(%{assigns | bubble_index: 3}, {"Green-E", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
      end
    end

    test "boylston through copley" do
      for direction <- [0, 1] do
        for stop <- ["place-boyls", "place-armnl", "place-coecl"] do
          assigns = %{@green_assigns | stop_id: stop, direction_id: direction}
          for {branch, index} <- GreenLine.branch_ids() do
            assert stop_bubble_classes(%{assigns | bubble_index: index}, {branch, :stop}) == @normal_stop_classes
          end
        end
      end
    end

    test "hynes" do
      for direction <- [0, 1] do
        assigns = %{@green_assigns | stop_id: "place-hymnl", direction_id: direction}
        for {branch, index} <- Enum.with_index ["B", "C", "D"] do
          assert stop_bubble_classes(%{assigns | bubble_index: index}, {"Green-" <> branch, :stop}) ==
            {@stop_class, @solid_line <> @direction_class[direction]}
        end
      end
    end

    test "kenmore" do
      for {branch, index} <- Enum.with_index ["B", "C", "D"] do
        assigns = %{@green_assigns | stop_id: "place-kencl", bubble_index: index}
        bubble = {"Green-" <> branch, :stop}
        assert stop_bubble_classes(assigns, bubble) == {@stop_class, @dotted_line <> @direction_class[0]}
        assert stop_bubble_classes(%{assigns | direction_id: 1}, bubble) ==
          {@stop_class, @solid_line <> @direction_class[1]}
      end
    end

    test "E branch stops" do
      heath = %{@green_assigns | stop_id: "place-hsmnl", stop_branch: "Green-E"}
      assert stop_bubble_classes(heath, {"Green-E", :terminus}) == {@terminus_class, ""}
      assert stop_bubble_classes(%{heath | direction_id: 1}, {"Green-E", :terminus}) ==
        {@terminus_class, @dotted_line <> @direction_class[1]}
      assert stop_bubble_classes(heath, {"Green-B", :line}) == {"", @solid_line <> @direction_class[0]}
      assert stop_bubble_classes(%{heath | direction_id: 1}, {"Green-B", :line}) ==
        {"", @solid_line <> @direction_class[1]}
    end

    test "Non-E branch stops" do
      for direction <- [0, 1] do
        assigns = %{@green_assigns | stop_id: "place-bland", stop_branch: "Green-B",
                                  expanded: "Green-B",
                                  direction_id: direction}
        assert stop_bubble_classes(assigns, {"Green-B", :stop}) ==
          {@stop_class, @solid_line <> @direction_class[direction]}
      end
    end

    test "branch terminii" do
      branch_terminii = %{
        "Green-B" => "place-lake",
        "Green-C" => "place-clmnl",
        "Green-D" => "place-river"
      }
      [b, c, d] = Enum.map(["B", "C", "D"], fn letter ->
        branch = "Green-" <> letter
        %{@green_assigns | stop_id: branch_terminii[branch], stop_branch: branch}
      end)
      b_1_expanded = %{b | direction_id: 1, expanded: "Green-B"}
      c_1_expanded = %{c | direction_id: 1, expanded: "Green-C"}

      assert stop_bubble_classes(b, {"Green-B", :terminus}) == {@terminus_class, ""}
      assert stop_bubble_classes(%{b | expanded: "Green-B"}, {"Green-B", :terminus}) == {@terminus_class, ""}
      assert stop_bubble_classes(%{b | direction_id: 1}, {"Green-B", :terminus}) ==
        {@terminus_class, @dotted_line <> @direction_class[1]}
      assert stop_bubble_classes(b_1_expanded, {"Green-B", :terminus}) ==
        {@terminus_class, @solid_line <> @direction_class[1]}
      assert stop_bubble_classes(c, {"Green-B", :line}) == {"", @dotted_line <> @direction_class[0]}
      assert stop_bubble_classes(%{c | expanded: "Green-B"}, {"Green-B", :line}) ==
        {"", @solid_line <> @direction_class[0]}
      assert stop_bubble_classes(c, {"Green-C", :terminus}) == {@terminus_class, ""}
      assert stop_bubble_classes(d, {"Green-B", :line}) == {"", @dotted_line <> @direction_class[0]}
      assert stop_bubble_classes(%{d | expanded: "Green-B"}, {"Green-B", :line}) ==
        {"", @solid_line <> @direction_class[0]}
      assert stop_bubble_classes(%{c | direction_id: 1}, {"Green-C", :terminus}) ==
        {@terminus_class, @dotted_line <> @direction_class[1]}
      assert stop_bubble_classes(c_1_expanded, {"Green-C", :terminus}) ==
        {@terminus_class, @solid_line <> @direction_class[1]}
    end
  end

  describe "expanded branches" do
    test "braintree has a solid line and terminus bubble when braintree is expanded and direction is 1" do
      assigns = %Params{expanded: "Braintree", stop_id: "place-brntn", stop_number: 0, stop_branch: "Braintree",
                  route_id: "Red", route_type: 1, line_only?: false, vehicle_tooltip: nil, direction_id: 1}
      assert stop_bubble_classes(assigns, {"Braintree", :terminus}) ==
        {@terminus_class, @solid_line <> @direction_class[1]}
    end
  end

  def render_stop_bubble_content(assigns, {branch, bubble_type}) do
    assigns
    |> stop_bubble_content({branch, bubble_type})
    |> Enum.map(& if &1 == "", do: "", else: safe_to_string(&1))
    |> Enum.join()
  end

  def stop_bubble_classes(assigns, bubble) do
    assigns
    |> stop_bubble_content(bubble)
    |> parse_html()
    |> do_stop_bubble_classes()
  end

  defp do_stop_bubble_classes(""), do: ""
  defp do_stop_bubble_classes(["", ""]), do: {"", ""}
  defp do_stop_bubble_classes([element]), do: {get_element_class(element), ""}
  defp do_stop_bubble_classes(elements) when is_list(elements), do: elements
                                                                    |> Enum.map(&get_element_class/1)
                                                                    |> List.to_tuple()

  defp parse_html(element_list) do
    Enum.map(element_list, &do_parse_html/1)
  end

  defp do_parse_html(element) do
    case element do
      {:safe, content} -> Floki.parse(content)
      "" -> ""
    end
  end

  defp get_element_class(""), do: ""
  defp get_element_class({"svg", [{"class", "icon " <> bubble_class} | _], _}), do: bubble_class
  defp get_element_class({"div", [{"class", class}], _}), do: class

end
