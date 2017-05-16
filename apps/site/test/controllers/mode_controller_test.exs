defmodule Site.ModeControllerTest do
  use Site.ConnCase, async: true

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
      assert response =~ "/schedules/commuter_rail"
    end

    test "mTicket not matched", %{conn: conn} do
      response = conn
      |> get(mode_path(conn, :commuter_rail))
      |> html_response(200)

      refute response =~ "mticket-notice"
    end
  end
end
