defmodule SiteWeb.ProjectControllerTest do
  use SiteWeb.ConnCase, async: true

  describe "index" do
    test "renders the list of projects", %{conn: conn} do
      conn = get conn, project_path(conn, :index)
      assert html_response(conn, 200) =~ "<h1>Transforming the T</h1>"
    end
  end

  describe "show" do
    test "renders a project when project has no path alias", %{conn: conn} do
      project = project_factory(0)
      assert project.path_alias == nil
      assert project.title == "Ruggles Station Platform Project"
      path = project_path(conn, :show, project)
      assert path == "/projects/2679"

      conn = get conn, path
      assert html_response(conn, 200) =~ "Ruggles Station Platform Project"
    end

    test "renders a project with a path alias", %{conn: conn} do
      project = project_factory(1)

      assert project.path_alias == "/projects/project-name"

      conn = get conn, project_path(conn, :show, project)
      assert html_response(conn, 200) =~ "<h1>Symphony, Hynes, and Wollaston Stations Accessibility Upgrades</h1>"
    end

    test "renders a preview of the requested project", %{conn: conn} do
      project = project_factory(1)
      conn = get(conn, project_path(conn, :show, project) <> "?preview&vid=112")
      assert html_response(conn, 200) =~ "Symphony, Hynes, and Wollaston Stations Accessibility Upgrades 112"
      assert %{"preview" => nil, "vid" => "112"} == conn.query_params
    end

    test "retains params and redirects with correct status code when CMS returns a native redirect", %{conn: conn} do
      conn = get conn, project_path(conn, :show, "redirected-project") <> "?preview&vid=999"
      assert conn.status == 301
      assert Plug.Conn.get_resp_header(conn, "location") == ["/projects/project-name?preview=&vid=999"]
    end

    test "renders a 404 given an valid id but mismatching content type", %{conn: conn} do
      conn = get conn, project_path(conn, :show, "17")
      assert conn.status == 404
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, project_path(conn, :show, "this-does-not-exist")
      assert conn.status == 404
    end
  end

  describe "project_update" do
    test "renders a project update when update has no path alias", %{conn: conn} do
      project_update = project_update_factory(1, path_alias: nil)

      assert project_update.path_alias == nil
      assert project_update.title == "Project Update Title 2"
      path = project_update_path(conn, :project_update, project_update)
      assert path == "/projects/2679/update/124"

      conn = get conn, path
      assert conn.status == 200
      assert html_response(conn, 200) =~ "Project Update Title 2"
    end

    test "renders a project update with a path alias", %{conn: conn} do
      project_update = project_update_factory(1)

      assert project_update.path_alias == "/projects/project-name/update/project-progress"

      conn = get conn, project_update_path(conn, :project_update, project_update)
      assert conn.status == 200
      assert html_response(conn, 200) =~ "<h1>Project Update Title 2</h1>"
    end

    test "renders a preview of the requested project update", %{conn: conn} do
      project_update = project_update_factory(1)
      conn = get(conn, project_update_path(conn, :project_update, project_update) <> "?preview&vid=112")
      assert conn.status == 200
      assert html_response(conn, 200) =~ "Project Update Title 2 112"
      assert %{"preview" => nil, "vid" => "112"} == conn.query_params
    end

    test "doesn't redirect update when project part of path would by itself return a native redirect", %{conn: conn} do
      conn = get conn, project_update_path(conn, :project_update, "redirected-project", "not-redirected-update")
      assert conn.status == 200
    end

    test "retains params and redirects with correct status code when CMS returns a native redirect", %{conn: conn} do
      conn = get conn, project_update_path(conn, :project_update, "project-name", "redirected-update") <> "?preview&vid=999"
      assert conn.status == 301
      assert Plug.Conn.get_resp_header(conn, "location") == ["/projects/project-name/update/project-progress?preview=&vid=999"]
    end

    test "renders a 404 given an valid id but mismatching content type", %{conn: conn} do
      conn = get conn, project_path(conn, :project_update, "2679", "17")
      assert conn.status == 404
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, project_path(conn, :project_update, "999", "999")
      assert conn.status == 404
    end

    test "renders a 404 given an invalid id when project found", %{conn: conn} do
      conn = get conn, project_path(conn, :project_update, "2679", "999")
      assert conn.status == 404
    end

    test "renders a 404 when project update exists but project does not exist", %{conn: conn} do
      path = project_path(conn, :project_update, "project-deleted", "project-deleted-progress")
      assert %Content.ProjectUpdate{project_url: "/projects/project-deleted"} = Content.Repo.get_page(path)
      assert conn
             |> project_path(:show, "project-deleted")
             |> Content.Repo.get_page() == {:error, :not_found}
      conn = get conn, path
      assert conn.status == 404
    end
  end
end
