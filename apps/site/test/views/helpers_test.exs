defmodule Site.HelpersTest do
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers

  use Site.ConnCase, async: true

  describe "route_icon/2" do
    test "for Red line" do
      assert "<i class=\"fa fa-circle fa-color-subway-red\" aria-hidden=true></i>" == safe_to_string(route_icon(0, "Red"))
    end

    test "for Green line D" do
      assert "<i class=\"fa fa-circle fa-color-subway-green-d\" aria-hidden=true></i>" == safe_to_string(route_icon(1, "Green-D"))
    end

    test "for Bus line 4" do
      assert "" == safe_to_string(route_icon(3, "4"))
    end
  end

  describe "route_link/2" do
    test "for Orange line" do
      conn = conn :get, "/stations/place-north"
      route = %Routes.Route{type: 0, id: "Orange", name: "Orange"}

      expected = 
        "<a class=\"mode-group-btn\" href=\"/schedules?route=Orange\">" <>  
        safe_to_string(route_icon(route.type, route.id)) <>
        " Orange</a>"

      assert expected == safe_to_string(route_link(conn, route))
    end

    test "for Lowell line" do
      conn = conn :get, "/stations/place-north"
      route = %Routes.Route{type: 2, id: "CR-Lowell", name: "Lowell"}

      expected = "<a class=\"mode-group-btn\" href=\"/schedules?route=CR-Lowell\">Lowell</a>"
      assert expected == safe_to_string(route_link(conn, route))
    end
  end
end
