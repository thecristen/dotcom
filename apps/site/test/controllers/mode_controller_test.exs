defmodule Site.ModeControllerTest do
  use Site.ConnCase, async: true

  test "renders each of the separate mode pages", %{conn: conn} do
    for mode <- ~W(index subway bus ferry commuter_rail)a do
      assert conn
      |> get(mode_path(conn, mode))
      |> html_response(200)
    end
  end
end
