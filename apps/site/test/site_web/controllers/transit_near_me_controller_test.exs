defmodule SiteWeb.TransitNearMeControllerTest do
  use SiteWeb.ConnCase

  test "index is under a flag", %{conn: conn} do
    assert conn
           |> get(transit_near_me_path(conn, :index))
           |> Map.fetch!(:status) == 404

    assert conn
           |> put_req_cookie("transit_near_me_redesign", "true")
           |> get(transit_near_me_path(conn, :index))
           |> Map.fetch!(:status) == 200
  end
end
