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
end
