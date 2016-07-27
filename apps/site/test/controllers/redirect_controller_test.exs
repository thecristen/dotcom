defmodule Site.RedirectControllerTest do
  use Site.ConnCase, async: true

  test "shows chosen resource", %{conn: conn} do
    redirect = "schedules_and_maps/"
    conn = get conn, redirect_path(conn, :show, redirect)
    response = html_response(conn, 200)
    assert response =~ "http://www.mbta.com/schedules_and_maps/"
    assert response =~ "http://mobile.usablenet.com/mt/www.mbta.com/schedules_and_maps/"
  end
end
