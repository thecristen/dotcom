defmodule Site.StopControllerTest do
  use Site.ConnCase, async: true

  alias Site.StopController
  alias Alerts.Alert
  alias Alerts.InformedEntity, as: IE

  @alerts [
    %Alert{effect_name: "Delay", informed_entity: [%IE{route: "Red", stop: "place-sstat"}], updated_at: ~N[2017-01-01T12:00:00]},
    %Alert{effect_name: "Access Issue", informed_entity: [%IE{stop: "place-pktrm"}]},
    %Alert{effect_name: "Access Issue", informed_entity: [%IE{stop: "place-sstat"}, %IE{route: "Red"}], updated_at: ~N[2017-01-01T12:00:00]}
  ]

  test "redirects to subway stops on index", %{conn: conn} do
    conn = get conn, stop_path(conn, :index)
    assert redirected_to(conn) == stop_path(conn, :show, :subway)
  end

  test "shows stations by mode", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, :subway)
    response = html_response(conn, 200)
    for line <- ["Green", "Red", "Blue", "Orange", "Mattapan"] do
      assert response =~ line
    end
  end

  test "shows stations", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "place-portr")
    assert html_response(conn, 200) =~ "Porter"
    assert conn.assigns.breadcrumbs == [
      {stop_path(conn, :index), "Stations"},
      "Porter"
    ]
  end

  test "shows stops", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "22")
    assert html_response(conn, 200) =~ "E Broadway @ H St"
    assert conn.assigns.breadcrumbs == [
      "E Broadway @ H St"
    ]
  end

  test "can show stations with spaces", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "Anderson/ Woburn")
    assert html_response(conn, 200) =~ "Anderson/Woburn"
  end

  test "Tab defaults to 'info'", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "place-sstat")
    assert conn.assigns.tab == "info"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, stop_path(conn, :show, -1)
    end
  end

  test "assigns the terminal station of CR lines from a station", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "Anderson/ Woburn", tab: "info")
    assert conn.assigns.terminal_station == "place-north"
    conn = get conn, stop_path(conn, :show, "Readville", tab: "info")
    assert conn.assigns.terminal_station == "place-sstat"
  end

  test "assigns an empty terminal station for non-CR stations", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "22", tab: "info")
    assert conn.assigns.terminal_station == ""
  end

  test "assigns alerts for the stop", %{conn: conn} do
    conn = conn
    |> assign(:all_alerts, @alerts)
    |> get(stop_path(conn, :show, "place-sstat", tab: "schedule"))

    assert conn.assigns.stop_alerts == [0, 2] |> Enum.map(&Enum.at(@alerts, &1))
  end

  test "does not assign stop alerts on info page", %{conn: conn} do
    conn = conn
    |> assign(:all_alerts, @alerts)
    |> get(stop_path(conn, :show, "place-sstat", tab: "info"))

    refute conn.assigns[:stop_alerts]
  end

  test "assigns nearby fare retail locations", %{conn: conn} do
    assert %Plug.Conn{assigns: %{fare_sales_locations: locations}} = get conn, stop_path(conn, :show, "place-sstat", tab: "info")
    assert is_list(locations)
    assert length(locations) == 4
    assert {%Fares.RetailLocations.Location{agent: "Patriot News"}, _} = List.first(locations)
  end

  test "renders a google maps link for every fare retail location", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "place-sstat", %{"tab" => "info"})
    assert %Plug.Conn{assigns: %{fare_sales_locations: locations, stop: %{latitude: stop_lat, longitude: stop_lng}}} = conn
    for location <- locations do
      assert {%{latitude: retail_lat, longitude: retail_lng}, _distance} = location
      assert html_response(conn, 200) =~ "https://maps.google.com/maps/dir/#{stop_lat},#{stop_lng}/#{retail_lat},#{retail_lng}"
    end
  end

  test "assigns the google maps requirement only when info tab is selected", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "Anderson/ Woburn", tab: "info")
    assert conn.assigns.requires_google_maps?
    conn = get conn, stop_path(conn, :show, "Readville", tab: "schedule")
    refute conn.assigns[:requires_google_maps?]
  end

  test "assigns upcoming_route_departures when schedule tab is selected", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "place-sstat", tab: "schedule")
    assert conn.assigns.upcoming_route_departures
  end

  test "Only render map when info tab is selected", %{conn: conn} do
    conn = get conn, stop_path(conn, :show, "Anderson/ Woburn", tab: "info")
    assert html_response(conn, 200) =~ "station-map-container"
    conn = get conn, stop_path(conn, :show, "Readville", tab: "schedule")
    refute html_response(conn, 200) =~ "station-map-container"
  end

  describe "access_alerts/2" do
    test "returns only access issues which affect the given stop" do
      assert StopController.access_alerts(@alerts, %Stops.Stop{id: "place-sstat"}) == [
        Enum.at(@alerts, 2)
      ]
      assert StopController.access_alerts(@alerts, %Stops.Stop{id: "place-davis"}) == []
    end
  end
end
