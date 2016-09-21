defmodule Site.LayoutViewTest do
  use Site.ConnCase, async: true

  import Phoenix.HTML

  import Site.LayoutView

  test "bold_if_active makes text bold if the current request is made against the given path", %{conn: conn} do
    conn = get conn, "/schedules/subway"
    assert bold_if_active(conn, "/schedules", "test") == raw("<strong>test</strong>")
  end

  test "renders breadcrumbs in the title", %{conn: conn} do
    conn = get conn, "/schedules/subway"
    body = html_response(conn, 200)

    expected_title = "Subway < Schedules & Maps < MBTA - Massachusetts Bay Transportation Authority"
    assert body =~ "<title>#{expected_title |> Plug.HTML.html_escape}</title>"
  end

  test "does not include a redirect link to itself in the footer", %{conn: conn} do
    for redirect <- ["customer_support/privacy_policy/", "customer_support/terms_of_use/"] do
      conn = get conn, Site.ViewHelpers.redirect_path(conn, redirect)
      response = html_response(conn, 200)
      refute response =~ ~s(href="/redirect/${redirect}")
    end
  end
end
