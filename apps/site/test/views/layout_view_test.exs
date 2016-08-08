defmodule Site.LayoutViewTest do
  use Site.ConnCase, async: true

  import Phoenix.HTML

  import Site.LayoutView

  test "bold_if_active makes text bold if the current request is made against the given path" do
    conn = build_conn :get, "/schedules/subway"
    assert bold_if_active(conn, "/schedules", "test") == raw("<strong>test</strong>")
  end
end
