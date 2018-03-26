defmodule SiteWeb.SearchV2ControllerTest do
  use SiteWeb.ConnCase, async: true
  describe "index" do
    test "renders search results page if flag is enabled", %{conn: conn} do
      conn = put_req_cookie(conn, "search_v2", "true")
      conn = get conn, search_v2_path(conn, :index)
      assert html_response(conn, 200) =~ "Search by keyword"
    end

    test "404 if flag is disabled", %{conn: conn} do
      conn = put_req_cookie(conn, "search_v2", "false")
      conn = get conn, search_v2_path(conn, :index)
      assert conn.status == 404
    end

    test "stops_with_alerts/1" do
      stops_fn = fn() -> [%Stops.Stop{id: "stop_without_alert"}, %Stops.Stop{id: "stop_with_alert"}] end
      ie_stop_with_alert = %Alerts.InformedEntity{stop: "stop_with_alert"}
      alerts = [%Alerts.Alert{id: "alert1",
                              severity: 8,
                              active_period: [{Timex.shift(Timex.now(), days: -1), Timex.shift(Timex.now(), days: 1)}],
                              informed_entity: Alerts.InformedEntitySet.new([ie_stop_with_alert])
                             }
               ]

      assert SiteWeb.SearchV2Controller.stops_with_alerts(alerts, stops_fn) == ["stop_with_alert"]
    end

    test "routes_with_alerts/1" do
      routes_fn = fn() -> [%Routes.Route{id: "route_without_alert"}, %Routes.Route{id: "route_with_alert"}] end
      ie_route_with_alert = %Alerts.InformedEntity{route: "route_with_alert"}
      alerts = [%Alerts.Alert{id: "alert1",
                              severity: 8,
                              active_period: [{Timex.shift(Timex.now(), days: -1), Timex.shift(Timex.now(), days: 1)}],
                              informed_entity: Alerts.InformedEntitySet.new([ie_route_with_alert])
                             }
               ]

      assert SiteWeb.SearchV2Controller.routes_with_alerts(alerts, routes_fn) == ["route_with_alert"]
    end
  end
end
