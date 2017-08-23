defmodule Site.RedirectControllerTest do
  use Site.ConnCase, async: true

  test "shows chosen resource", %{conn: conn} do
    redirect = "schedules_and_maps/"
    conn = get conn, redirect_path(conn, :show, [redirect])
    response = html_response(conn, 200)
    assert response =~ "http://old.mbta.com/" <> redirect
  end

  test "does not include the mobile link for t-alerts", %{conn: conn} do
    redirect = "rider_tools/t_alerts"
    conn = get conn, redirect_path(conn, :show, [redirect])
    response = html_response(conn, 200)
    assert response =~ "http://old.mbta.com/" <> redirect
  end

  test "handles resources with slashes", %{conn: conn} do
    conn = get conn, "/redirect/rider_tools/transit_updates"
    response = html_response(conn, 200)
    assert response =~ "http://old.mbta.com/rider_tools/transit_updates"
  end

  test "handles resource with query params", %{conn: conn} do
    conn = get conn, redirect_path(conn, :show, ["news"], entry: "123")
    response = html_response(conn, 200)
    assert response =~ "http://old.mbta.com/news?entry=123"
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

  test "send refresh header, allow turbolinks", %{conn: conn} do
    attribute = conn
    |> put_req_header("turbolinks-referrer", "/")
    |> get("/redirect/riding_the_t/bikes/")
    |> html_response(200)
    |> Floki.find("body")
    |> Floki.attribute("data-turbolinks")

    assert attribute == ["true"]
  end

  test "does not add a refresh header when coming from an outside source", %{conn: conn} do
    header = conn
    |> put_req_header("referer", "http://www.google.com")
    |> get("/redirect/riding_the_t/bikes/")
    |> get_resp_header("refresh")

    assert header == []
  end

  test "adds the refresh header when the request is coming from the same host and turbolinks is disabled", %{conn: conn} do
    conn = conn
    |> put_req_header("host", "localhost:4001")
    |> put_req_header("referer", "http://localhost:4001/")
    |> get("/redirect/riding_the_t/bikes/")

    assert conn |> get_resp_header("refresh") == ["5;url=http://old.mbta.com/riding_the_t/bikes"]

    attribute = conn
    |> html_response(200)
    |> Floki.find("body")
    |> Floki.attribute("data-turbolinks")

    assert attribute == ["false"]
  end

  test "does not add the refresh header when the request has no referer", %{conn: conn} do
    header = conn
    |> put_req_header("host", "localhost:4001")
    |> get("/redirect/riding_the_t/bikes/")
    |> get_resp_header("refresh")

    assert header == []
  end
end
