defmodule Site.RedirectControllerTest do
  use Site.ConnCase, async: true

  test "shows chosen resource", %{conn: conn} do
    redirect = "schedules_and_maps/"
    conn = get conn, redirect_path(conn, :show, [redirect])
    response = html_response(conn, 200)
    assert response =~ "http://www.mbta.com/" <> redirect
  end

  test "does not include the mobile link for t-alerts", %{conn: conn} do
    redirect = "rider_tools/t_alerts"
    conn = get conn, redirect_path(conn, :show, [redirect])
    response = html_response(conn, 200)
    assert response =~ "http://www.mbta.com/" <> redirect
  end

  test "handles resources with slashes", %{conn: conn} do
    conn = get conn, "/redirect/rider_tools/transit_updates"
    response = html_response(conn, 200)
    assert response =~ "http://www.mbta.com/rider_tools/transit_updates"
  end

  test "handles resource with query params", %{conn: conn} do
    conn = get conn, redirect_path(conn, :show, ["news"], entry: "123")
    response = html_response(conn, 200)
    assert response =~ "http://www.mbta.com/news?entry=123"
  end

  test "handles pass program subdomain", %{conn: conn} do
    conn = get conn, "/redirect/pass_program"
    response = html_response(conn, 200)
    assert response =~ "https://passprogram.mbta.com/"
  end

  test "handles pass program subdomain with slashes", %{conn: conn} do
    conn = get conn, "/redirect/pass_program/Public/transit"
    response = html_response(conn, 200)
    assert response =~ "https://passprogram.mbta.com/Public/transit"
  end

  test "handles pass program subdomain with query param", %{conn: conn} do
    conn = get conn, redirect_path(conn, :show, ["pass_program", "news"], entry: "123")
    response = html_response(conn, 200)
    assert response =~ "https://passprogram.mbta.com/news?entry=123"
  end

  test "handles commerce subdomain", %{conn: conn} do
    conn = get conn, "/redirect/commerce"
    response = html_response(conn, 200)
    assert response =~ "https://commerce.mbta.com/"
  end

  test "handles commerce subdomain with slashes", %{conn: conn} do
    conn = get conn, "/redirect/commerce/TheRide"
    response = html_response(conn, 200)
    assert response =~ "https://commerce.mbta.com/TheRide"
  end
end
