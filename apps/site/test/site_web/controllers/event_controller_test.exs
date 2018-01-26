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
    test "renders an event when the given event has no path_alias", %{conn: conn} do
      event = event_factory(0, path_alias: nil)
      assert event.path_alias == nil
      conn = get conn, event_path(conn, :show, event)
      assert html_response(conn, 200) =~ "Finance & Audit Committee Meeting"
    end

    test "disambiguation: renders an event whose alias pattern is /events/:title instead of /events/:date/:title", %{conn: conn} do
      conn = get conn, event_path(conn, :show, "incorrect-pattern")
      assert html_response(conn, 200) =~ "AACT Executive Board Meeting"
    end

    test "renders the given event with a path_alias", %{conn: conn} do
      event = event_factory(1)

      assert event.path_alias == "/events/date/title"
      conn = get conn, event_path(conn, :show, event)
      assert html_response(conn, 200) =~ "AACT Executive Board Meeting"
    end

    test "renders a preview of the requested event", %{conn: conn} do
      event = event_factory(1)
      conn = get(conn, event_path(conn, :show, event) <> "?preview&vid=112")
      assert html_response(conn, 200) =~ "AACT Executive Board Meeting 112"
      assert %{"preview" => nil, "vid" => "112"} == conn.query_params
    end

    test "renders a 404 given an valid id but mismatching content type", %{conn: conn} do
      conn = get conn, event_path(conn, :show, "1")
      assert conn.status == 404
    end

    test "renders a 404 when event does not exist", %{conn: conn} do
      conn = get conn, event_path(conn, :show, "2018", "invalid-event")
      assert conn.status == 404
    end
  end
end
