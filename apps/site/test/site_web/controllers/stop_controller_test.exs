defmodule SiteWeb.StopControllerTest do
  use SiteWeb.ConnCase

  test "view is under a flag", %{conn: conn} do
    assert conn
           |> get(stop_path(conn, :show, "place-sstat"))
           |> Map.fetch!(:status) == 404

    assert conn
           |> put_req_cookie("stop_page_redesign", "true")
           |> get(stop_path(conn, :show, "place-sstat"))
           |> Map.fetch!(:status) == 200
  end

  test "assigns routes for this stop", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "place-sstat"))

    assert conn.assigns.routes
  end

  test "assigns the zone number for the current stop", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "Worcester"))

    assert conn.assigns.zone_number == "8"
  end

  test "sets a custom meta description for stops", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "place-sstat"))

    assert conn.assigns.meta_description
  end

  test "404s for an unknown stop", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("stop_page_redesign", "true")
      |> get(stop_path(conn, :show, "unknown"))

    assert Map.fetch!(conn, :status) == 404
  end
end
