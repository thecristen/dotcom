defmodule Site.OldSiteRedirectControllerTest do
  use Site.ConnCase, async: true

  describe "/uploadedfiles" do
    test "can return a file with spaces in the URL", %{conn: conn} do
      conn = head conn, "/uploadedfiles/Documents/Schedules_and_Maps/Rapid Transit w Key Bus.pdf"
      assert conn.status == 200
    end
  end

  describe "/rider_tools" do
    test "realtime bus/subway redirects to schedules", %{conn: conn} do
      assert redirected_to(get(conn, "/rider_tools/realtime_subway")) =~ mode_url(Site.Endpoint, :subway)
      assert redirected_to(get(conn, "/rider_tools/realtime_bus")) =~ mode_url(Site.Endpoint, :bus)
    end

    test "service nearby redirects to transit near me", %{conn: conn} do
      assert redirected_to(get(conn, "/rider_tools/servicenearby/")) =~ transit_near_me_url(Site.Endpoint, :index)
    end

    test "transit updates redirects to alerts", %{conn: conn} do
      assert redirected_to(get(conn, "/rider_tools/transit_updates/")) =~ alert_url(Site.Endpoint, :index)
    end
  end

  describe "/schedules_and_maps" do
    test "Subway stop redirected to subway stops page", %{conn: conn} do
      old_url = "/schedules_and_maps/subway/lines/stations/?stopId=15481" # Ashmont
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :subway)
    end

    test "Bus stop redirected to subway stops page", %{conn: conn} do
      old_url = "schedules_and_maps/subway/lines/stations/?stopId=11496" # Dudley Station
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :subway)
    end

    test "Commuter stop redirected to commuter rail stops page", %{conn: conn} do # Westborough
      old_url = "schedules_and_maps/rail/lines/stations/?stopId=16087"
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :commuter_rail)
    end

    test "Ferry stop redirected to ferry stops page", %{conn: conn} do
      old_url = "schedules_and_maps/boats/lines/stations/?stopId=25783" # Long Wharf
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :ferry)
    end
  end

  describe "fares_and_passes" do
    test "reduced fare programs redirects to /fares/reduced", %{conn: conn} do
      old_url = "/fares_and_passes/reduced_fare_programs/"
      assert redirected_to(get(conn, old_url)) =~ fare_url(Site.Endpoint, :show, :reduced)
    end

    test "sales_locations redirected to retail_sales_locations", %{conn: conn} do
      old_url = "/fares_and_passes/sales_locations/"
      assert redirected_to(get(conn, old_url)) =~ fare_url(Site.Endpoint, :show, :retail_sales_locations)
    end

    test "base mticket page redirects to payment methods", %{conn: conn} do
      old_url = "http://old.mbta.com/fares_and_passes/mticketing/"
      assert redirected_to(get(conn, old_url)) =~ fare_url(Site.Endpoint, :show, :payment_methods)
    end

    test "mticket how-to redirects to commuter_rail how-to-pay", %{conn: conn} do
      old_url = "/fares_and_passes/mticketing/?id=25905"
      assert redirected_to(get(conn, old_url)) =~ how_to_pay_url(Site.Endpoint, :show, :commuter_rail)
    end

    test "mticket customer support redirects to customer support", %{conn: conn} do
      old_url = "http://old.mbta.com/fares_and_passes/mticketing/?id=25904"
      assert redirected_to(get(conn, old_url)) =~ customer_support_url(Site.Endpoint, :index)
    end
  end

  describe "customer_support" do
    test "redirected to new customer support page", %{conn: conn} do
      old_url = "/customer_support/contact/"
      assert redirected_to(get(conn, old_url)) =~ customer_support_url(Site.Endpoint, :index)
    end
  end
end
