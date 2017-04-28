defmodule Site.EventControllerTest do
  use Site.ConnCase, async: true

  describe "GET index" do
    test "renders a list of upcoming events", %{conn: conn} do
      conn = get conn, event_path(conn, :index)
      assert html_response(conn, 200) =~ "Upcoming Events"
    end

    test "scopes events based on provided dates", %{conn: conn} do
      conn = get conn, event_path(conn, :index, %{month: "2017-01-01"})
      assert html_response(conn, 200) =~ "Finance &amp; Audit Committee Meeting"
    end
  end

  describe "GET show" do
    test "renders the given event", %{conn: conn} do
      conn = get conn, event_path(conn, :show, "17")
      assert html_response(conn, 200) =~ "Finance &amp; Audit Committee Meeting"
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, event_path(conn, :show, "999")
      end
    end
  end
end
