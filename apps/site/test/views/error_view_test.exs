defmodule Site.ErrorViewTest do
  use Site.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "adds 'not-found' to body class on 404 pages" do
    conn = get build_conn(), "/not-found"
    assert html_response(conn, 404) =~ "not-found"
  end

  test "renders 404.html" do
    assert render_to_string(Site.ErrorView, "404.html", []) =~ "the page you're looking for has been derailed and cannot be found."
  end

  test "render 500.html" do
    assert render_to_string(Site.ErrorView, "500.html", []) =~ "It looks like we have our signals crossed"
  end

  test "crash pages links to the Google form" do
    assert render_to_string(Site.ErrorView, "500.html", []) =~ Site.ViewHelpers.feedback_form_url
  end

  test "render any other" do
    assert render_to_string(Site.ErrorView, "505.html", []) =~ "It looks like we have our signals crossed"
  end
end
