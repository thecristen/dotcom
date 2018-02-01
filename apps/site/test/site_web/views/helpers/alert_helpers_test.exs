defmodule SiteWeb.Views.Helpers.AlertHelpersTest do
  use SiteWeb.ConnCase, async: true
  import SiteWeb.Views.Helpers.AlertHelpers

  describe "alert_line_show_path/2" do
    test "Returns line path given a real route id", %{conn: conn} do
      assert alert_line_show_path(conn, "Red") == "/schedules/Red/line"
    end

    test "Returns /accessibility path given fake 'Other' route id", %{conn: conn} do
      assert alert_line_show_path(conn, "Other") == "/accessibility"
    end

    test "Returns /accessibility path given fake 'Elevator' route id", %{conn: conn} do
      assert alert_line_show_path(conn, "Elevator") == "/accessibility"
    end

    test "Returns /accessibility path given fake 'Escalator' route id", %{conn: conn} do
      assert alert_line_show_path(conn, "Escalator") == "/accessibility"
    end
  end
end
