defmodule SiteWeb.Plugs.RewriteUrlsTest do
  @moduledoc false
  use SiteWeb.ConnCase, async: true
  import SiteWeb.Plugs.RewriteUrls

  describe "call/2" do
    test "redirects if we're going to /schedules/Boat-F3", %{conn: conn} do
      conn = %{conn | path_info: ["schedules", "Boat-F3"], request_path: "/schedules/Boat-F3"}
      conn = call(conn, [])
      assert redirected_to(conn, 302) == "/schedules/Boat-F1"
      assert conn.halted
    end

    test "temporarily redirects route 62 to the combined 627 pages, for service adjustments in Fall 2020",
         %{conn: conn} do
      conn = %{conn | path_info: ["schedules", "62", "line"], request_path: "/schedules/62/line"}
      conn = call(conn, [])
      assert redirected_to(conn, 302) == "/schedules/627/line"
      assert conn.halted
    end

    test "temporarily redirects route 76 to the combined 627 pages, for service adjustments in Fall 2020",
         %{conn: conn} do
      conn = %{conn | path_info: ["schedules", "76", "line"], request_path: "/schedules/76/line"}
      conn = call(conn, [])
      assert redirected_to(conn, 302) == "/schedules/627/line"
      assert conn.halted
    end

    test "includes a query string if present", %{conn: conn} do
      conn = %{
        conn
        | path_info: ["schedules", "Boat-F3", "schedules"],
          request_path: "/schedules/Boat-F3/schedules",
          query_string: "query=string"
      }

      conn = call(conn, [])
      assert redirected_to(conn, 302) == "/schedules/Boat-F1/schedules?query=string"
      assert conn.halted
    end

    test "ignores other URLs", %{conn: conn} do
      conn = call(conn, [])
      refute conn.state == :set
      refute conn.halted
    end
  end
end
