defmodule SiteWeb.EventControllerTest do
  use SiteWeb.ConnCase, async: true

  describe "GET index" do
    test "renders a list of upcoming events", %{conn: conn} do
      conn = get conn, event_path(conn, :index)
      assert html_response(conn, 200) =~ Timex.format!(Util.today, "{Mfull}")
    end

    test "scopes events based on provided dates", %{conn: conn} do
      conn = get conn, event_path(conn, :index, %{month: "2017-01-01"})
      assert html_response(conn, 200) =~ "Finance &amp; Audit Committee Meeting"
    end
  end

  describe "GET show" do
    test "renders the given event with no path_alias", %{conn: conn} do
      event = event_factory(0)
      conn = get conn, event_path(conn, :show, event)
      assert html_response(conn, 200) =~ "Finance &amp; Audit Committee Meeting"
    end

    test "renders the given event with a path_alias", %{conn: conn} do
      event = event_factory(1)
      conn = get conn, event_path(conn, :show, event)
      assert html_response(conn, 200) =~ "AACT Executive Board Meeting"
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      IO.puts SiteWeb.Router.Helpers.event_path(conn, :show, "999")
      conn = get conn, SiteWeb.Router.Helpers.event_path(conn, :show, "999")
      assert conn.status == 404
    end
  end
end
