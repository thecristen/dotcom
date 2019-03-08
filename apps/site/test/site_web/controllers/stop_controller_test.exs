defmodule SiteWeb.StopControllerTest do
  use SiteWeb.ConnCase

  test "view is under a flag", %{conn: conn} do
    assert conn
           |> get(stop_path(conn, :show, "abc"))
           |> Map.fetch!(:status) == 404

    assert conn
           |> put_req_cookie("stop_page_redesign", "true")
           |> get(stop_path(conn, :show, "abc"))
           |> Map.fetch!(:status) == 200
  end
end
