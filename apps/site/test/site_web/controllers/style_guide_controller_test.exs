defmodule SiteWeb.StyleGuideControllerTest do
  use Site.Components.Register
  use SiteWeb.ConnCase, async: true

  test "style-guide links to invision dsg" do
    conn = get build_conn(), "style-guide"
    assert html_response(conn, 301)
  end
  test "style-guide/* links to style-guide/" do
    conn = get build_conn(), "style-guide/some_path"
    assert html_response(conn, 301)
  end
end
