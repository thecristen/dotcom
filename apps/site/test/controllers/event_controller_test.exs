defmodule Site.EventControllerTest do
  use Site.ConnCase
  import Mock

  describe "GET index" do
    test "renders a list of events for the current month", %{conn: conn} do
      event = event_page_factory()

      with_mock Content.Repo, [all: fn("events", _params) -> [event] end] do
        conn = get conn, event_path(conn, :index)

        assert html_response(conn, 200) =~ event.title
        assert html_response(conn, 200) =~ "Upcoming Meetings"
      end
    end
  end

  describe "GET show" do
    test "renders the given event", %{conn: conn} do
      event = event_page_factory()

      with_mock Content.Repo, [get!: fn("events", _id) -> event end] do
        conn = get conn, event_path(conn, :show, event.id)

        assert html_response(conn, 200) =~ event.title
      end
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      with_mock Content.Repo, [get!: fn("events", _id) -> raise Content.NoResultsError end] do
        assert_error_sent 404, fn ->
          conn = get conn, event_path(conn, :show, 999)

          assert html_response(conn, 404) =~ "Your stop cannot be found."
        end
      end
    end
  end
end
