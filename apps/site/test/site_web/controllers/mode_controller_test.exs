defmodule SiteWeb.ModeControllerTest do
  use SiteWeb.ConnCase, async: true

  for mode <- ~W(index subway bus ferry commuter_rail)a do
    test_name = "renders the #{mode} mode page"
    test test_name, %{conn: conn} do
      assert conn
      |> get(mode_path(conn, unquote(mode)))
      |> html_response(200)
    end
  end

  test "test mode redirect route_id", %{conn: conn} do
    assert conn
    |> get(mode_path(conn, :index, route: "CR-Fitchburg"))
    |> redirected_to() == "/schedules/CR-Fitchburg"
  end

  describe "mTicket detection" do
    test "mTicket matched", %{conn: conn} do
      response = conn
      |> put_req_header("user-agent", "Java/1.8.0_91")
      |> get(mode_path(conn, :commuter_rail))
      |> html_response(200)

      assert response =~ "mticket-notice"
      assert response =~ "access schedules:"
      assert response =~ "/schedules/commuter-rail"
    end

    test "mTicket not matched", %{conn: conn} do
      response = conn
      |> get(mode_path(conn, :commuter_rail))
      |> html_response(200)

      refute response =~ "mticket-notice"
    end
  end

  describe "index" do
    test "index page redirects to line page when valid filter is specified", %{conn: conn} do
      conn = get(conn, mode_path(conn, :bus, %{"filter" => %{"q" => "sL1"}}))
      assert redirected_to(conn) == line_path(conn, :show, "741")
    end

    test "index page does not redirect when given invalid route name", %{conn: conn} do
      conn = get(conn, mode_path(conn, :bus, %{"filter" => %{"q" => "invalid_Route-name"}}))
      assert html_response(conn, 200)
    end

    test "index page does not redirect when given valid non-bus route", %{conn: conn} do
      conn = get(conn, mode_path(conn, :bus, %{"filter" => %{"q" => "CR-Fitchburg"}}))
      assert html_response(conn, 200)
    end

    test "puts search_error in flash when route is not found", %{conn: conn} do
      conn = get(conn, mode_path(conn, :bus, %{"filter" => %{"q" => "invalid"}}))
      assert get_flash(conn, :search_error) == "invalid"
    end

    test "index page only redirects for bus", %{conn: conn} do
      conn = get(conn, mode_path(conn, :subway, %{"filter" => %{"q" => "sL1"}}))
      assert html_response(conn, 200)
    end
  end
end
