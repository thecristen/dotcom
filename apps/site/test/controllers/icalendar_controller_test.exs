defmodule Site.IcalendarControllerTest do
  use Site.ConnCase, async: true

  describe "GET show" do
    test "returns an icalendar file as an attachment", %{conn: conn} do
      conn = get conn, event_icalendar_path(conn, :show, "17")

      assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/calendar; charset=utf-8"]
      assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
        "attachment; filename='finance_&_audit_committee_meeting.ics'"
      ]
    end
  end
end
