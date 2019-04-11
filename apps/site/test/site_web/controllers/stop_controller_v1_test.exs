defmodule SiteWeb.StopV1ControllerTest do
  use SiteWeb.ConnCase
  import Site.PageHelpers, only: [breadcrumbs_include?: 2]

  alias Alerts.Alert
  alias Alerts.InformedEntity, as: IE
  alias Routes.Route
  alias SiteWeb.StopV1Controller
  alias Stops.Stop
  alias Util.Breadcrumb

  @alerts [
    Alert.new(
      effect: :delay,
      informed_entity: [%IE{route: "Red", stop: "place-sstat"}],
      updated_at: ~N[2017-01-01T12:00:00]
    ),
    Alert.new(
      effect: :access_issue,
      informed_entity: [%IE{stop: "place-pktrm"}]
    ),
    Alert.new(
      effect: :access_issue,
      informed_entity: [%IE{stop: "place-sstat"}, %IE{route: "Red"}],
      updated_at: ~N[2017-01-01T12:00:00]
    )
  ]

  test "redirects to subway stops on index", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :index))
    assert redirected_to(conn) == stop_v1_path(conn, :show, :subway)
  end

  test "shows stations by mode", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, :subway))
    response = html_response(conn, 200)

    for line <- ["Green", "Red", "Blue", "Orange", "Mattapan"] do
      assert response =~ line
    end
  end

  test "assigns stop_info for each mode", %{conn: conn} do
    for mode <- [:subway, :ferry, "commuter-rail"] do
      conn = get(conn, stop_v1_path(conn, :show, mode))
      assert conn.assigns.stop_info
    end
  end

  test "shows stations", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-portr"))

    body = html_response(conn, 200)
    assert body =~ "Porter"
    assert breadcrumbs_include?(body, ["Stations", "Porter"])
  end

  test "shows bus-only stations", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-crtst"))

    body = html_response(conn, 200)
    assert body =~ "Courthouse"
    assert breadcrumbs_include?(body, "Courthouse")
  end

  test "redirects stations with slashes to the right URL", %{conn: conn} do
    conn = get(conn, "/stops/Four%20Corners%20/%20Geneva")
    assert redirected_to(conn) == stop_v1_path(conn, :show, "Four Corners / Geneva")
  end

  test "separates mattapan from stop info", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, :subway))
    assert conn.assigns.mattapan
    stop_info_routes = Enum.map(conn.assigns.stop_info, fn {route, _stops} -> route.id end)
    refute "Mattapan" in stop_info_routes
  end

  test "shows stops", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "22"))

    body = html_response(conn, 200)
    assert body =~ "E Broadway @ H St"
    assert breadcrumbs_include?(body, "E Broadway @ H St")
  end

  test "redirects to a parent stop page for a child stop", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, 9_070_130))
    assert redirected_to(conn) == stop_v1_path(conn, :show, "place-harvd")
  end

  test "sets a custom meta description for stops", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "22"))
    assert conn.assigns.meta_description
  end

  test "can show stations with spaces", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Anderson/ Woburn"))
    assert html_response(conn, 200) =~ "Anderson/Woburn"
  end

  test "Tab defaults to 'info'", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat"))
    assert conn.assigns.tab == "info"
  end

  test "Tab defaults to `info` when given invalid tab param", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat", tab: "weather"))
    assert conn.assigns.tab == "info"
  end

  test "redirects to departures tab when 'schedule' provided as tab param", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat", tab: "schedule"))
    assert redirected_to(conn) == stop_v1_path(conn, :show, "place-sstat", tab: "departures")
  end

  test "Tab assigned when given valid param", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat", tab: "info"))
    assert conn.assigns.tab == "info"
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat", tab: "departures"))
    assert conn.assigns.tab == "departures"
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat", tab: "alerts"))
    assert conn.assigns.tab == "alerts"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, -1))
    assert html_response(conn, 404)
  end

  test "assigns the fare name for the commuter rail from the current stop to Zone 1A", %{
    conn: conn
  } do
    conn = get(conn, stop_v1_path(conn, :show, "Worcester", tab: "info"))
    assert conn.assigns.fare_name == {:zone, "8"}
  end

  test "assigns nil as the fare name for a ferry with multiple options ", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Boat-Long", tab: "info"))
    assert conn.assigns.fare_name == nil
  end

  test "assigns the only available fare from stops with a single destination", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Boat-Charlestown", tab: "info"))
    assert conn.assigns.fare_name == :ferry_inner_harbor
  end

  test "assigns the terminal station of CR lines from a station", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Anderson/ Woburn", tab: "info"))
    assert conn.assigns.terminal_stations[2] == "place-north"
    conn = get(conn, stop_v1_path(conn, :show, "Readville", tab: "info"))
    assert conn.assigns.terminal_stations[2] == "place-sstat"
  end

  test "assigns the terminal station for a ferry if there is only one possibility", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Boat-Charlestown", tab: "info"))
    assert conn.assigns.terminal_stations[4] == "Boat-Long-South"
  end

  test "assigns an empty terminal station for a ferry if there are multiple possibilities", %{
    conn: conn
  } do
    conn = get(conn, stop_v1_path(conn, :show, "Boat-Logan", tab: "info"))
    assert conn.assigns.terminal_stations[4] == ""
  end

  test "assigns an empty terminal station for non-CR/Ferry stations", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "22", tab: "info"))
    assert conn.assigns.terminal_stations[2] == ""
    assert conn.assigns.terminal_stations[4] == ""
  end

  test "does assign stop alerts on info page", %{conn: conn} do
    conn =
      conn
      |> assign(:alerts, @alerts)
      |> get(stop_v1_path(conn, :show, "place-sstat", tab: "info"))

    assert conn.assigns[:alerts]
  end

  test "does assign stop alerts on alerts tab", %{conn: conn} do
    conn =
      conn
      |> assign(:alerts, @alerts)
      |> get(stop_v1_path(conn, :show, "place-sstat", tab: "alerts"))

    assert html_response(conn, 200) =~ "3 alerts"
  end

  test "renders a google maps link for every fare retail location", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat", %{"tab" => "info"}))

    assert %Plug.Conn{
             assigns: %{
               fare_sales_locations: locations,
               stop: %{latitude: stop_lat, longitude: stop_lng}
             }
           } = conn

    for location <- locations do
      assert {%{latitude: retail_lat, longitude: retail_lng}, _distance} = location

      assert html_response(conn, 200) =~
               "https://maps.google.com/maps/dir/#{stop_lat},#{stop_lng}/#{retail_lat},#{
                 retail_lng
               }"
    end
  end

  test "assigns the google maps requirement only when info tab is selected", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Anderson/ Woburn", tab: "info"))
    assert conn.assigns.requires_google_maps?
    conn = get(conn, stop_v1_path(conn, :show, "Readville", tab: "departures"))
    refute conn.assigns[:requires_google_maps?]
  end

  test "assigns upcoming_route_departures when departures tab is selected", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "place-sstat", tab: "departures"))
    assert conn.assigns.upcoming_route_departures
  end

  test "Only render map when info tab is selected", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Anderson/ Woburn", tab: "info"))
    assert html_response(conn, 200) =~ "station-map-container"
    conn = get(conn, stop_v1_path(conn, :show, "Readville", tab: "departures"))
    refute html_response(conn, 200) =~ "station-map-container"
    refute conn.assigns[:map_info]
  end

  test "assigns map info for tab info", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Anderson/ Woburn", tab: "info"))
    assert conn.assigns.map_info
  end

  test "Assigns specific fare for Charlestown Ferry", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Boat-Charlestown", tab: "info"))
    assert html_response(conn, 200) =~ "Inner Harbor Ferry One-Way"
    refute html_response(conn, 200) =~ "All ferry routes"
  end

  test "Does not assign specific fares for Long Wharf Ferry stop", %{conn: conn} do
    conn = get(conn, stop_v1_path(conn, :show, "Boat-Long", tab: "info"))
    assert html_response(conn, 200) =~ "All ferry routes"
  end

  describe "breadcrumbs/2" do
    test "returns station breadcrumbs if the stop is served by more than buses" do
      stop = %Stop{name: "Name", station?: true}
      routes = [%Route{id: "CR-Lowell", type: 2}]

      assert StopV1Controller.breadcrumbs(stop, routes) == [
               %Breadcrumb{text: "Stations", url: "/stops/commuter-rail"},
               %Breadcrumb{text: "Name", url: ""}
             ]
    end

    test "returns simple breadcrumb if the stop is served by only buses" do
      stop = %Stop{name: "Dudley Station"}
      routes = [%Route{id: "28", type: 3}]

      assert StopV1Controller.breadcrumbs(stop, routes) == [
               %Breadcrumb{text: "Dudley Station", url: ""}
             ]
    end

    test "returns simple breadcrumb if we have no route info for the stop" do
      stop = %Stop{name: "Name", station?: true}
      assert StopV1Controller.breadcrumbs(stop, []) == [%Breadcrumb{text: "Name", url: ""}]
    end
  end
end
