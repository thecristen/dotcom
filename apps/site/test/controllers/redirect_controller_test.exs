defmodule Site.RedirectControllerTest do
  use Site.ConnCase, async: true

  test "shows chosen resource", %{conn: conn} do
    redirect = "schedules_and_maps/"
    conn = get conn, redirect_path(conn, :show, redirect)
    assert html_response(conn, 200) =~ "http://mbta.com/schedules_and_maps/"
  end
end
