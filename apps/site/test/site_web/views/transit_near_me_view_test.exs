defmodule SiteWeb.TransitNearMeViewTest do
  use SiteWeb.ConnCase, async: true
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias SiteWeb.TransitNearMeView, as: View

  @stop_with_routes %{
    distance: 0.52934802,
    routes: [
     orange_line: [%Routes.Route{id: "Orange", description: :rapid_transit, name: "Orange Line", type: 1}],
     commuter_rail: [
       %Routes.Route{id: "CR-Worcester", description: :commuter_rail, name: "Framingham/Worcester Line", type: 2},
       %Routes.Route{id: "CR-Franklin", description: :commuter_rail, name: "Franklin Line", type: 2},
       %Routes.Route{id: "CR-Needham", description: :commuter_rail, name: "Needham Line", type: 2},
       %Routes.Route{id: "CR-Providence", description: :commuter_rail, name: "Providence/Stoughton Line", type: 2}
      ],
      bus: [
        %Routes.Route{id: "10", description: :local_bus, name: "10", type: 3},
        %Routes.Route{id: "39", description: :key_bus_route, name: "39", type: 3},
        %Routes.Route{id: "170", description: :limited_service, name: "170", type: 3}
      ]
    ],
    stop: %Stops.Stop{
      accessibility: ["accessible", "elevator", "tty_phone", "escalator_up"],
      address: "145 Dartmouth St Boston, MA 02116-5162",
      id: "place-bbsta",
      latitude: 42.34735,
      longitude: -71.075727,
      name: "Back Bay",
      station?: true
    }
  }


  test "get_type_list/1" do
    @stop_with_routes
    |> Map.get(:routes)
    |> Enum.each(&test_get_type_list/1)
  end

  test "result_container_classes/2 assigns the correct class based on the result set size" do
    large_set = Enum.map(0..8, fn _ -> @stop_with_routes end)
    assert View.result_container_classes("different-class", large_set) == "different-class large-set"

    six_set = Enum.map(0..6, fn _ -> @stop_with_routes end)
    assert View.result_container_classes("different-class", six_set) == "different-class small-set"

    small_set = Enum.map(0..4, fn _ -> @stop_with_routes end)
    assert View.result_container_classes("different-class", small_set) == "different-class small-set"

    assert View.result_container_classes("different-class", []) == "different-class empty"
  end

  defp test_get_type_list({:bus, routes}) do
    assert :bus |> View.get_type_list(routes) |> safe_to_string =~ "Bus: "
  end
  defp test_get_type_list({mode_name, routes}) do
    assert View.get_type_list(mode_name, routes) =~ mode_name
                                                    |> Atom.to_string
                                                    |> String.split("_")
                                                    |> Enum.map(&String.capitalize/1)
                                                    |> Enum.join(" ")
  end
end
