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
      assert event.title == "Finance & Audit Committee Meeting"
      path = event_path(conn, :show, event)
      assert path == "/events/17"
      conn = get conn, path
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
      conn = get(conn, event_path(conn, :show, event) <> "?preview&vid=112&nid=5")
      assert html_response(conn, 200) =~ "AACT Executive Board Meeting 112"
      assert %{"preview" => nil, "vid" => "112", "nid" => "5"} == conn.query_params
    end

    test "retains params (except _format) and redirects when CMS returns a native redirect", %{conn: conn} do
      conn = get conn, event_path(conn, :show, "redirected-url") <> "?preview&vid=999"
      assert conn.status == 301
      assert Plug.Conn.get_resp_header(conn, "location") == ["/events/date/title?preview=&vid=999"]
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

  describe "GET icalendar" do
    test "returns an icalendar file as an attachment when event does not have an alias", %{conn: conn} do
      event = event_factory(0)
      assert event.path_alias == nil
      assert event.title == "Finance & Audit Committee Meeting"
      conn = get conn, event_icalendar_path(conn, :show, event)
      assert conn.status == 200

      assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/calendar; charset=utf-8"]
      assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
        "attachment; filename='finance_&_audit_committee_meeting.ics'"
      ]
    end

    test "returns an icalendar file as an attachment when event has a valid alias", %{conn: conn} do
      event = event_factory(1)
      assert event.path_alias == "/events/date/title"
      assert event.title == "AACT Executive Board Meeting"
      conn = get conn, event_icalendar_path(conn, :show, event)
      assert conn.status == 200

      assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/calendar; charset=utf-8"]
      assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
        "attachment; filename='aact_executive_board_meeting.ics'"
      ]
    end

    test "returns an icalendar file as an attachment when event has a non-conforming alias", %{conn: conn} do
      event = event_factory(0, path_alias: "/events/incorrect-pattern")
      assert event.path_alias == "/events/incorrect-pattern"
      conn = get conn, event_icalendar_path(conn, :show, event)
      assert conn.status == 200

      assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/calendar; charset=utf-8"]
      assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
        "attachment; filename='aact_executive_board_meeting.ics'"
      ]
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      event = event_factory(0, id: 999)
      conn = get conn, event_icalendar_path(conn, :show, event)
      assert conn.status == 404
    end

    test "renders an icalendar file for a redirected event", %{conn: conn} do
      event = event_factory(0, path_alias: "/events/redirected-url")
      assert event.path_alias == "/events/redirected-url"
      conn = get conn, event_icalendar_path(conn, :show, event)
      assert conn.status == 200
      assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/calendar; charset=utf-8"]
      assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
        "attachment; filename='aact_executive_board_meeting.ics'"
      ]
    end

    test "redirects old icalendar path to new icalendar path", %{conn: conn} do
      event = event_factory(1)
      old_path = Path.join(event_path(conn, :show, event), "icalendar")
      assert old_path == "/events/date/title/icalendar"
      conn = get conn, old_path
      assert conn.status == 302
    end
  end
end
