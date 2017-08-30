defmodule Site.OldSiteRedirectControllerTest do
  use Site.ConnCase, async: true

  describe "/uploadedfiles" do
    test "can return a file with spaces in the URL", %{conn: conn} do
      conn = head conn, "/uploadedfiles/Documents/Schedules_and_Maps/Rapid Transit w Key Bus.pdf"
      assert conn.status == 200
    end

    test "can return file from s3", %{conn: conn} do
      conn = head conn, "/uploadedfiles/feed_info.txt"
      assert conn.status == 200
    end

    test "returns 404 when uploaded file does not exist", %{conn: conn} do
      conn = head conn, "/uploadedfiles/file-not-found.txt"
      assert conn.status == 404
    end
  end

  describe "/gtfs_archive" do
    test "can return archived file from s3", %{conn: conn} do
      conn = head conn, "/gtfs_archive/archived_feeds.txt"
      assert conn.status == 200
    end

    test "returns 404 when archived file does not exist", %{conn: conn} do
      conn = head conn, "/gtfs_archive/file-not-found.txt"
      assert conn.status == 404
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
      old_url = "/schedules_and_maps/subway/lines/stations/"
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :subway)
    end

    test "Bus stop redirected to subway stops page", %{conn: conn} do
      old_url = "schedules_and_maps/subway/lines/stations/"
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :subway)
    end

    test "Commuter stop redirected to commuter rail stops page", %{conn: conn} do
      old_url = "schedules_and_maps/rail/lines/stations/"
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :commuter_rail)
    end

    test "Ferry stop redirected to ferry stops page", %{conn: conn} do
      old_url = "schedules_and_maps/boats/lines/stations/"
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, :ferry)
    end

    test "Specific stops redirect to corresponding stop page", %{conn: conn} do
      old_url = "schedules_and_maps/rail/lines/stations/?stopId=19"
      assert redirected_to(get(conn, old_url)) =~ stop_url(Site.Endpoint, :show, "Beverly")
    end

    test "Redirects to stop page regardless of incomming mode", %{conn: conn} do
      north_station_subway = "schedules_and_maps/subway/lines/stations?stopId=141"
      north_station_rail = "schedules_and_maps/rail/lines/stations?stopId=13610"

      assert redirected_to(get(conn, north_station_subway)) =~ stop_url(Site.Endpoint, :show, "place-north")
      assert redirected_to(get(conn, north_station_rail)) =~ stop_url(Site.Endpoint, :show, "place-north")
    end

    test "Redirects to mode page if stopId is not found", %{conn: conn} do
      invalid_rail_url = "schedules_and_maps/rail/lines/stations?stopId=invalidstopid"
      assert redirected_to(get(conn, invalid_rail_url)) =~ stop_url(Site.Endpoint, :show, :commuter_rail)
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
