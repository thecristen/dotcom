defmodule Site.RedirectControllerTest do
  use Site.ConnCase

  test "shows chosen resource", %{conn: conn} do
    redirect = "schedules_and_maps/"
    conn = get conn, redirect_path(conn, :show, redirect)
    assert html_response(conn, 200) =~ "http://www.mbta.com/schedules_and_maps/"
  end
end
