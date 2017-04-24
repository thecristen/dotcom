defmodule Site.LayoutViewTest do
  use Site.ConnCase, async: true

  import Phoenix.HTML

  import Site.LayoutView

  describe "_beta_announcement.html" do
    test "links to the feedback form", %{conn: conn} do
      conn = fetch_query_params(conn)
      output = "_beta_announcement.html" |> render(conn: conn) |> safe_to_string
      assert output =~ Site.ViewHelpers.feedback_form_url()
    end
  end

  describe "bold_if_active/3" do
    test "bold_if_active makes text bold if the current request is made against the given path", %{conn: conn} do
      conn = %{conn | request_path: "/schedules/subway"}
      assert bold_if_active(conn, "/schedules", "test") == raw("<strong>test</strong>")
    end

    test "bold_if_active only makes text bold if the current request is made to root path", %{conn: conn} do
      conn = %{conn | request_path: "/"}
      assert bold_if_active(conn, "/", "test") == raw("<strong>test</strong>")
      assert bold_if_active(conn, "/schedules", "test") == raw("test")
    end
  end

  test "renders breadcrumbs in the title", %{conn: conn} do
    conn = get conn, "/schedules/subway"
    body = html_response(conn, 200)

    expected_title = "Subway < Schedules & Maps < MBTA - Massachusetts Bay Transportation Authority"
    assert body =~ "<title>#{expected_title}</title>"
  end
end
