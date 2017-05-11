defmodule Site.ControllerHelpersTest do
  use Site.ConnCase, async: true
  import Site.ControllerHelpers

  describe "filter_modes/2" do
    test "filters the key routes of all modes that are passed" do
      routes = [
        {:subway, [%Routes.Route{direction_names: %{0 => "Southbound", 1 => "Northbound"},
         id: "Red", key_route?: true, name: "Red Line", type: 1},
        %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
         id: "Mattapan", key_route?: false, name: "Mattapan Trolley", type: 0}]},
        {:bus, [%Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "22",
         key_route?: true, name: "22", type: 3},
        %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "23",
         key_route?: true, name: "23", type: 3},
         %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "40",
             key_route?: false, name: "40", type: 3}]
      }]

      assert filter_routes(routes, [:subway, :bus]) ==
        [{:subway, [%Routes.Route{direction_names: %{0 => "Southbound", 1 => "Northbound"},
         id: "Red", key_route?: true, name: "Red Line", type: 1}]},
        {:bus, [%Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "22",
         key_route?: true, name: "22", type: 3},
        %Routes.Route{direction_names: %{0 => "Outbound", 1 => "Inbound"}, id: "23",
         key_route?: true, name: "23", type: 3}]}]
    end
  end

  describe "get_grouped_route_ids/1" do
    @grouped_routes [
      subway: [
        %Routes.Route{id: "sub1", type: 0},
        %Routes.Route{id: "sub2", type: 1}
      ],
      bus: [
        %Routes.Route{id: "bus1", type: 3}
      ],
      commuter_rail: [
        %Routes.Route{id: "comm1", type: 2},
        %Routes.Route{id: "comm2", type: 2}
      ]
    ]

    test "returns list of ids from the given grouped routes" do
      assert get_grouped_route_ids(@grouped_routes) == ["sub1", "sub2", "bus1", "comm1", "comm2"]
    end
  end
end
