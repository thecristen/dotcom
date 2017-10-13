defmodule Site.WwwRedirectorTest do
  use Site.ConnCase, async: true
  import Phoenix.ConnTest, only: [redirected_to: 1]

  alias Site.WwwRedirector

  test "top level redirected", %{conn: conn} do
    check_redirect(conn, "/", nil, "https://www.mbta.com/")
    check_redirect(conn, "", nil, "https://www.mbta.com")
  end

  test "with path redirected", %{conn: conn} do
    check_redirect(conn, "/schedules", nil, "https://www.mbta.com/schedules")
  end

  test "with path and query string redirected", %{conn: conn} do
    check_redirect(
      conn,
      "/schedules/Boat-F4/schedule",
      "destination=Boat-Long",
      "https://www.mbta.com/schedules/Boat-F4/schedule?destination=Boat-Long")
  end

  test "with path and query string with anchor redirected", %{conn: conn} do
    check_redirect(
      conn,
      "/schedules/Boat-F4/schedule",
      "destination=Boat-Long&direction_id=1&origin=Boat-Charlestown#direction-filter",
      "https://www.mbta.com/schedules/Boat-F4/schedule?destination=Boat-Long&direction_id=1&origin=Boat-Charlestown#direction-filter")
  end

  defp check_redirect(conn, request_path, query_string, expected_url) do
    conn = %{conn | request_path: request_path, query_string: query_string}
    conn = WwwRedirector.site_redirect("https://www.mbta.com", conn)
    assert redirected_to(conn) == expected_url
    assert conn.status == 302
    assert conn.halted
  end
end
