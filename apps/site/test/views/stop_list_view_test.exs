defmodule Site.StopListViewTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2View.StopList
  alias Stops.RouteStop
  alias Routes.Route

  describe "stop_bubble_row_params/2" do
    test "flattens the assigns into the map needed for the stop bubbles for a particular row" do
      assigns = %{
        bubbles: [{"branch", :terminus}],
        stop: %RouteStop{branch: "branch", stop_number: 1, id: "stop"},
        route: %Route{id: "route_id", type: 1},
        direction_id: 1,
        conn: "conn",
        add_expand_link?: false,
        expanded: true,
        branch_names: ["branch"],
        vehicle_tooltip: %VehicleTooltip{},
        row_content_template: "_line_page_stop_info.html"
      }

      params = stop_bubble_row_params(assigns)

      assert %Site.PartialView.StopBubbles.Params{
        bubbles: [{"branch", :terminus}],
        stop_number: 1,
        stop_branch: "branch",
        stop_id: "stop",
        route_id: "route_id",
        route_type: 1,
        direction_id: 1,
        expanded: true,
        branch_names: ["branch"],
        vehicle_tooltip: %VehicleTooltip{},
        is_expand_link?: false
      } = params
    end

    test "sets :is_expand_link? to true when passed in" do
      assigns = %{
        bubbles: [{"branch", :terminus}],
        stop: %RouteStop{branch: "branch", stop_number: 1, id: "stop"},
        route: %Route{id: "route_id", type: 1},
        direction_id: 1,
        conn: "conn",
        add_expand_link?: false,
        expanded: true,
        branch_names: ["branch"],
        vehicle_tooltip: %VehicleTooltip{},
        row_content_template: "_line_page_stop_info.html"
      }

      params = stop_bubble_row_params(assigns, true)

      assert params.is_expand_link?
    end
  end
end
