defmodule Site.LayoutViewTest do
  use Site.ConnCase, async: true

  import Phoenix.HTML

  import Site.LayoutView

  test "bold_if_active makes text bold if the current request is made against the given path", %{conn: conn} do
    conn = get conn, "/schedules/subway"
    assert bold_if_active(conn, "/schedules", "test") == raw("<strong>test</strong>")
  end

  describe "format_header_fare/1" do
    test "given a list of fare filters, finds the fare that fits and formats its price" do
      assert format_header_fare(mode: :subway, duration: :single_trip, media: [:charlie_card]) == "$2.25"
    end
  end

  test "renders breadcrumbs in the title", %{conn: conn} do
    conn = get conn, "/schedules/subway"
    body = html_response(conn, 200)

    expected_title = "Subway < Schedules & Maps < MBTA - Massachusetts Bay Transportation Authority"
    assert body =~ "<title>#{expected_title |> Plug.HTML.html_escape}</title>"
  end
end
