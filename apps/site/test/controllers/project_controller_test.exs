defmodule Site.ProjectControllerTest do
  use Site.ConnCase, async: true

  describe "index" do
    test "renders the list of projects", %{conn: conn} do
      conn = get conn, project_path(conn, :index)
      assert html_response(conn, 200) =~ "<h1>T-Projects</h1>"
    end
  end
end
