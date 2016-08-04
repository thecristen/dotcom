defmodule Site.HelpersTest do
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  import Site.ViewHelpers

  use Site.ConnCase, async: true

  test "route icon for Red line" do
    assert raw("<i class=\"fa fa-circle fa-color-subway-red\" aria-hidden=true></i>") == route_icon(0, "Red")
  end

  test "route icon for Green line D" do
    assert raw("<i class=\"fa fa-circle fa-color-subway-green-d\" aria-hidden=true></i>") == route_icon(1, "Green-D")
  end

  test "route icon for Bus line 4" do
    assert raw("") == route_icon(3, "4")
  end

  test "route link for Red line" do
    conn = conn :get, "/stations/place-north"
    route = %Routes.Route{type: 0, id: "Orange", name: "Orange"}

    expected = "<a class=\"mode-group-btn\" href=\"/schedules?route=Orange\"><i class=\"fa fa-circle fa-color-subway-orange\" aria-hidden=true></i> Orange</a>"
    assert expected == safe_to_string(route_link(conn, route))
  end

  test "route link for Lowell line" do
    conn = conn :get, "/stations/place-north"
    route = %Routes.Route{type: 2, id: "CR-Lowell", name: "Lowell"}

    expected = "<a class=\"mode-group-btn\" href=\"/schedules?route=CR-Lowell\"> Lowell</a>"
    assert expected == safe_to_string(route_link(conn, route))
  end
end
