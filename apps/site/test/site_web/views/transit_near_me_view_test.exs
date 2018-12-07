defmodule SiteWeb.TransitNearMeViewTest do
  use SiteWeb.ConnCase, async: true
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias SiteWeb.TransitNearMeView, as: View

  @stop %Stops.Stop{
    accessibility: ["accessible", "elevator", "tty_phone", "escalator_up"],
    address: "145 Dartmouth St Boston, MA 02116-5162",
    id: "place-bbsta",
    latitude: 42.34735,
    longitude: -71.075727,
    name: "Back Bay",
    station?: true
  }

  @routes [
    orange_line: [
      %Routes.Route{id: "Orange", description: :rapid_transit, name: "Orange Line", type: 1}
    ],
    commuter_rail: [
      %Routes.Route{
        id: "CR-Worcester",
        description: :commuter_rail,
        name: "Framingham/Worcester Line",
        type: 2
      },
      %Routes.Route{
        id: "CR-Franklin",
        description: :commuter_rail,
        name: "Franklin Line",
        type: 2
      },
      %Routes.Route{id: "CR-Needham", description: :commuter_rail, name: "Needham Line", type: 2},
      %Routes.Route{
        id: "CR-Providence",
        description: :commuter_rail,
        name: "Providence/Stoughton Line",
        type: 2
      }
    ],
    bus: [
      %Routes.Route{id: "10", description: :local_bus, name: "10", type: 3},
      %Routes.Route{id: "39", description: :key_bus_route, name: "39", type: 3},
      %Routes.Route{id: "170", description: :limited_service, name: "170", type: 3}
    ]
  ]

  @stop_with_routes %{
    distance: 0.52934802,
    routes: @routes,
    stop: @stop
  }

  test "result_container_classes/2 assigns the correct class based on the result set size" do
    large_set = Enum.map(0..8, fn _ -> @stop_with_routes end)

    assert View.result_container_classes("different-class", large_set) ==
             "different-class large-set"

    six_set = Enum.map(0..6, fn _ -> @stop_with_routes end)

    assert View.result_container_classes("different-class", six_set) ==
             "different-class small-set"

    small_set = Enum.map(0..4, fn _ -> @stop_with_routes end)

    assert View.result_container_classes("different-class", small_set) ==
             "different-class small-set"

    assert View.result_container_classes("different-class", []) == "different-class empty"
  end

  test "render_routes/2" do
    Enum.each(@routes, &test_render_routes/1)
  end

  defp test_render_routes({:bus, routes}) do
    assert :bus |> View.render_routes(routes, @stop) |> safe_to_string =~ "Bus: "
  end

  defp test_render_routes({mode_name, routes}) do
    expected =
      mode_name
      |> Atom.to_string()
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    actual =
      mode_name
      |> View.render_routes(routes, @stop)
      |> safe_to_string()

    assert actual =~ expected
  end
end
