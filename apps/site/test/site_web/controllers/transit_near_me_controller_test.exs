defmodule SiteWeb.TransitNearMeControllerTest do
  use SiteWeb.ConnCase

  alias GoogleMaps.{Geocode.Address, MapData, MapData.Marker}
  alias Routes.Route
  alias SiteWeb.TransitNearMeController, as: TNMController
  alias Stops.Stop

  @stop_with_routes %{
    distance: 0.52934802,
    routes: [
      orange_line: [
        %Route{id: "Orange", description: :rapid_transit, name: "Orange Line", type: 1}
      ],
      commuter_rail: [
        %Route{
          id: "CR-Worcester",
          description: :commuter_rail,
          name: "Framingham/Worcester Line",
          type: 2
        },
        %Route{id: "CR-Franklin", description: :commuter_rail, name: "Franklin Line", type: 2},
        %Route{id: "CR-Needham", description: :commuter_rail, name: "Needham Line", type: 2},
        %Route{
          id: "CR-Providence",
          description: :commuter_rail,
          name: "Providence/Stoughton Line",
          type: 2
        }
      ],
      bus: [
        %Route{id: "10", description: :local_bus, name: "10", type: 3},
        %Route{id: "39", description: :key_bus_route, name: "39", type: 3},
        %Route{id: "170", description: :limited_service, name: "170", type: 3}
      ]
    ],
    stop: %Stop{
      accessibility: ["accessible", "elevator", "tty_phone", "escalator_up"],
      address: "145 Dartmouth St Boston, MA 02116-5162",
      id: "place-bbsta",
      latitude: 42.34735,
      longitude: -71.075727,
      name: "Back Bay",
      station?: true
    }
  }

  test "index is under a flag", %{conn: conn} do
    assert conn
           |> get(transit_near_me_path(conn, :index))
           |> Map.fetch!(:status) == 404

    assert conn
           |> put_req_cookie("transit_near_me_redesign", "true")
           |> get(transit_near_me_path(conn, :index))
           |> Map.fetch!(:status) == 200
  end

  describe "assign_map_data/1" do
    test "initializes a map with no markers", %{conn: conn} do
      conn =
        conn
        |> assign(:stops_with_routes, [])
        |> assign(:location, nil)
        |> TNMController.assign_map_data()

      assert %MapData{} = conn.assigns.map_data
      assert conn.assigns.map_data.markers == []
    end

    test "assigns a marker for all stops", %{conn: conn} do
      conn =
        conn
        |> assign(:stops_with_routes, [@stop_with_routes])
        |> assign(:location, nil)
        |> TNMController.assign_map_data()

      assert %MapData{} = conn.assigns.map_data
      assert [marker] = conn.assigns.map_data.markers
      assert %Marker{} = marker
      assert marker.latitude == @stop_with_routes.stop.latitude
      assert marker.longitude == @stop_with_routes.stop.longitude
      assert marker.tooltip =~ "c-location-card__name"
    end

    test "assigns a marker with a bus icon for stops that aren't stations", %{conn: conn} do
      bus_stop_with_routes = put_in(@stop_with_routes.stop.station?, false)
      conn =
        conn
        |> assign(:stops_with_routes, [@stop_with_routes, bus_stop_with_routes])
        |> assign(:location, nil)
        |> TNMController.assign_map_data()

      assert %MapData{} = conn.assigns.map_data
      assert [marker, bus_marker] = conn.assigns.map_data.markers
      assert %Marker{} = bus_marker
      assert bus_marker.icon == "map-stop-marker"
      assert put_in(bus_marker.icon, "map-station-marker") == marker
    end

    test "assigns a marker for the provided location", %{conn: conn} do
      conn =
        conn
        |> assign(:stops_with_routes, [])
        |> assign(:location, %Address{
          formatted: "10 Park Plaza",
          latitude: @stop_with_routes.stop.latitude,
          longitude: @stop_with_routes.stop.longitude
        })
        |> TNMController.assign_map_data()

      assert [marker] = conn.assigns.map_data.markers
      assert marker.tooltip == "10 Park Plaza"
    end
  end
end
