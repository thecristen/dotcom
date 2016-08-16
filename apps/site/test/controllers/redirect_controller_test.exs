defmodule Site.RedirectControllerTest do
  use Site.ConnCase, async: true

  test "shows chosen resource", %{conn: conn} do
    redirect = "schedules_and_maps/"
    conn = get conn, redirect_path(conn, :show, redirect)
    response = html_response(conn, 200)
    assert response =~ "http://www.mbta.com/" <> redirect
    assert response =~ "http://mobile.usablenet.com/mt/www.mbta.com/" <> redirect
  end

  test "does not include the mobile link for t-alerts", %{conn: conn} do
    redirect = "rider_tools/t_alerts/"
    conn = get conn, redirect_path(conn, :show, redirect)
    response = html_response(conn, 200)
    assert response =~ "http://www.mbta.com/" <> redirect
    refute response =~ "http://mobile.usablenet.com/mt/www.mbta.com/" <> redirect
  end
end
