defmodule Site.ProjectControllerTest do
  use Site.ConnCase, async: true

  describe "index" do
    test "renders the list of projects if flag enabled", %{conn: conn} do
      conn = put_req_cookie(conn, "project_index", "true")
      conn = get conn, project_path(conn, :index)
      assert html_response(conn, 200) =~ "<h1>Transforming the T</h1>"
    end

    test "404s the list of projects if not enabled", %{conn: conn} do
      conn = get conn, project_path(conn, :index)
      assert conn.status == 404
    end
  end

  describe "show" do
    test "renders a project", %{conn: conn} do
      conn = get conn, project_path(conn, :show, "2679")
      assert html_response(conn, 200) =~ "<h1>Ruggles Station Platform Project</h1>"
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, project_path(conn, :show, "999")
      assert conn.status == 404
    end
  end

  describe "update" do
    test "renders a project update", %{conn: conn} do
      conn = get conn, project_path(conn, :project_update, "2679", "123")
      assert html_response(conn, 200) =~ "<h1>Project Update Title</h1>"
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, project_path(conn, :project_update, "999", "999")
      assert conn.status == 404
    end

    test "renders a 404 given an invalid id when project found", %{conn: conn} do
      conn = get conn, project_path(conn, :project_update, "2679", "999")
      assert conn.status == 404
    end
  end
end
