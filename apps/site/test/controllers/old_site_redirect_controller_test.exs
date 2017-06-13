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
end
