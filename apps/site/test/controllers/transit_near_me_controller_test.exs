defmodule Site.TransitNearMeControllerTest do
  use Site.ConnCase, async: true
  alias Stops.Stop
  alias Routes.Route

  @stop_with_routes %{
    distance: 0.52934802,
    routes: [
     orange_line: [%Routes.Route{id: "Orange", key_route?: true, name: "Orange Line", type: 1}],
     commuter_rail: [
       %Route{id: "CR-Worcester", key_route?: false, name: "Framingham/Worcester Line", type: 2},
       %Route{id: "CR-Franklin", key_route?: false, name: "Franklin Line", type: 2},
       %Route{id: "CR-Needham", key_route?: false, name: "Needham Line", type: 2},
       %Route{id: "CR-Providence", key_route?: false, name: "Providence/Stoughton Line", type: 2}
      ],
      bus: [
        %Route{id: "10", key_route?: false, name: "10", type: 3},
        %Route{id: "39", key_route?: true, name: "39", type: 3},
        %Route{id: "170", key_route?: false, name: "170", type: 3}
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


  describe "Transit Near Me" do
    test "display message if no results", %{conn: conn} do
      response = conn
      |> search_near_address("randomnonsensicalstringnoresults")
      |> html_response(200)
      assert response =~ "any stations found"
    end

    test "assigns results into different number of groups based on column width" do
      [{"1200", 12, 4}, {"800", 12, 3}, {"600", 12, 2}, {"300", 12, 1}]
      |> Enum.each(&test_column_assignment/1)
    end

    test "does not generate column groups if client_width is 0" do
      stops = stops_with_routes(12)
      assert %{assigns: assigns} = search_near_address(build_conn, "10 park plaza, boston ma", stops, "0")
      refute Map.get(assigns, :stop_groups)
    end
  end

  test "it contains the google maps scripts", %{conn: conn} do
    conn = conn
    |> get(transit_near_me_path(conn, :index))

    assert html_response(conn, 200) =~ "https://maps.googleapis.com/maps/api/js?libraries=places"
  end

  @spec search_near_address(Plug.Conn.t, String.t, [Stop.t], String.t) :: Plug.Conn.t
  def search_near_address(conn, address, stops \\ [], width \\ "1200") do
    conn
    |> assign(:stops_with_routes, stops)
    |> assign(:address, address)
    |> Phoenix.Controller.put_view(Site.TransitNearMeView)
    |> bypass_through(Site.Router, :browser)
    |> get(transit_near_me_path(conn, :index, %{"location" => %{"client_width" => width}}))
    |> Site.Plugs.TransitNearMe.call(Site.Plugs.TransitNearMe.init([]))
    |> Site.TransitNearMeController.index([])
  end

  @spec stops_with_routes(integer) :: [Stop.t]
  def stops_with_routes(num), do: Enum.map 1..num, fn _ -> @stop_with_routes end

  @spec test_column_assignment({String.t, integer, integer}) :: :ok
  defp test_column_assignment({width, num_results, expected}) do
    stops = stops_with_routes(num_results)
    assert %{assigns: %{stop_groups: groups}} = search_near_address(build_conn, "10 park plaza, boston ma", stops, width)
    assert {width, groups
                   |> Map.keys
                   |> length} == {width, expected}
    :ok
  end
end
