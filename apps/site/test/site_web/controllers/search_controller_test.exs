defmodule SiteWeb.SearchControllerTest do
  use SiteWeb.ConnCase, async: true
  alias Alerts.Alert
  import Mock

  @params %{"search" => %{"query" => "mbta"}}

  describe "index with js" do
    test "index", %{conn: conn} do
      conn = get conn, search_path(conn, :index)
      response = html_response(conn, 200)
      assert response =~ "Filter by type"
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

      result = SiteWeb.SearchController.get_alert_ids(dt, alerts_repo_fn)
      assert result == %{
        stop: MapSet.new(["stop_with_alert"]),
        route: MapSet.new(["route_with_alert"])
      }
    end
  end

  describe "index with params nojs" do
    test "search param", %{conn: conn} do
      conn = get conn, search_path(conn, :index, @params)
      response = html_response(conn, 200)
      # check pagination
      assert response =~ "Showing results 1-10 of 2083"

      # check highlighting
      assert response =~ "solr-highlight-match"

      # check links from each type of document result
      assert response =~ "/people/monica-tibbits-nutt?from=search"
      assert response =~ "/news/2014-02-13/mbta-payroll?from=search"
      assert response =~ "/safety/transit-police/office-the-chief?from=search"
      assert response =~ "/sites/default/files/2017-01/C. Perkins.pdf?from=search"
      assert response =~ "/events/2006-10-05/board-meeting?from=search"
      assert response =~ "/fares?a=b&amp;from=search"
    end

    test "include offset", %{conn: conn} do
      params = %{@params | "search" => Map.put(@params["search"], "offset", "3")}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "Showing results 31-40 of 2083"
    end

    test "include filter", %{conn: conn} do
      content_type = %{"event" => "true"}
      params = %{@params | "search" => Map.put(@params["search"], "content_type", content_type)}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "<input checked=\"checked\" id=\"content_type_event\" name=\"search[content_type][event]\" type=\"checkbox\" value=\"true\">"
    end

    test "no matches", %{conn: conn} do
      conn = get conn, search_path(conn, :index, %{"search" => %{"query" => "empty", "nojs" => true}})
      response = html_response(conn, 200)
      assert response =~ "There are no results matching"
    end

    test "empty search query", %{conn: conn} do
      conn = get conn, search_path(conn, :index, %{"search" => %{"query" => "", "nojs" => true}})
      response = html_response(conn, 200)
      assert response =~ "empty-search-page"
    end

    test "search server is returning an error", %{conn: conn} do
      with_mock Content.Repo, [search: fn(_, _, _) -> {:error, :error} end] do
        conn = get conn, search_path(conn, :index, @params)
        response = html_response(conn, 200)
        assert response =~ "Whoops"
      end
    end
  end
end
