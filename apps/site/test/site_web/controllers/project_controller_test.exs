defmodule SiteWeb.ProjectControllerTest do
  use SiteWeb.ConnCase, async: true

  describe "index" do
    test "renders the list of projects", %{conn: conn} do
      conn = get conn, project_path(conn, :index)
      assert html_response(conn, 200) =~ "<h1>Transforming the T</h1>"
    end
  end

  describe "show" do
    test "renders a project with no path alias", %{conn: conn} do
      project = project_factory()
      conn = get conn, project_path(conn, :show, project)
      assert html_response(conn, 200) =~ "<h1>Ruggles Station Platform Project</h1>"
    end

    test "renders a project with a path alias", %{conn: conn} do
      project = Content.CMS.Static.projects_response()
      |> Enum.at(1)
      |> Content.Project.from_api()

      conn = get conn, project_path(conn, :show, project)
      assert html_response(conn, 200) =~ "<h1>Symphony, Hynes, and Wollaston Stations Accessibility Upgrades</h1>"
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, SiteWeb.Router.Helpers.project_path(conn, :show, "999")
      assert conn.status == 404
    end
  end

  describe "update" do
    test "renders a project update", %{conn: conn} do
      conn = get conn, SiteWeb.Router.Helpers.project_path(conn, :project_update, "2679", "123")
      assert html_response(conn, 200) =~ "<h1>Project Update Title 1</h1>"
    end

    test "renders a project update with no path alias", %{conn: conn} do
      project_update = Content.CMS.Static.project_updates_response()
      |> Enum.at(0)
      |> Content.ProjectUpdate.from_api()

      conn = get conn, project_update_path(conn, :project_update, project_update)
      assert html_response(conn, 200) =~ "<h1>Project Update Title 1</h1>"
    end

    test "renders a project update with a path alias", %{conn: conn} do
      project_update = Content.CMS.Static.project_updates_response()
      |> Enum.at(1)
      |> Content.ProjectUpdate.from_api()

      conn = get conn, project_update_path(conn, :project_update, project_update)
      assert html_response(conn, 200) =~ "<h1>Project Update Title 2</h1>"
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
