defmodule Site.IcalendarControllerTest do
  use Site.ConnCase
  import Mock

  describe "GET show" do
    test "returns an icalendar file as an attachment", %{conn: conn} do
      event =
        event_page_factory()
        |> update_attribute(:title, "Important Meeting")

      with_mock Content.Repo, [get: fn("events", _params) -> event end] do
        conn = get conn, event_icalendar_path(conn, :show, event.id)

        assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/calendar; charset=utf-8"]
        assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
          "attachment; filename='important_meeting.ics'"
        ]
      end
    end
  end
end
