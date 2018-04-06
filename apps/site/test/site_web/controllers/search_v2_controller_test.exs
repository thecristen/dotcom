defmodule SiteWeb.SearchV2ControllerTest do
  use SiteWeb.ConnCase, async: true
  alias Alerts.Alert

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
  end

  describe "get_alert_ids/2" do
    test "builds a hash of stop and route ids" do
      dt = Util.to_local_time(~N[2018-03-01T12:00:00])

      route_entity = Alerts.InformedEntity.from_keywords(route: "route_with_alert")
      stop_entity = Alerts.InformedEntity.from_keywords(stop: "stop_with_alert")

      stop_alert = Alert.new(
        effect: :station_closure,
        severity: 9,
        updated_at: Timex.shift(dt, hours: -2),
        informed_entity: [stop_entity, route_entity]
      )
      refute Alert.is_notice?(stop_alert, dt)

      route_alert = Alert.new(
        effect: :suspension,
        severity: 9,
        updated_at: Timex.shift(dt, hours: -1),
        informed_entity: [route_entity]
      )
      refute Alert.is_notice?(route_alert, dt)

      alerts_repo_fn = fn %DateTime{} ->
        [
          stop_alert,
          route_alert
        ]
      end

      result = SiteWeb.SearchV2Controller.get_alert_ids(dt, alerts_repo_fn)
      assert result == %{
        stop: MapSet.new(["stop_with_alert"]),
        route: MapSet.new(["route_with_alert"])
      }
    end
  end
end
