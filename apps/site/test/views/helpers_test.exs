defmodule Site.HelpersTest do
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers

  use Site.ConnCase, async: true

  describe "route_icon/2" do
    test "for Red line" do
      expected = "<i class=\"fa fa-circle fa-color-subway-red\" aria-hidden=true></i>"
      actual = safe_to_string(route_icon(0, "Red"))
      assert expected == actual
    end

    test "for Green line D" do
      expected = "<i class=\"fa fa-circle fa-color-subway-green-d\" aria-hidden=true></i>"
      actual = safe_to_string(route_icon(1, "Green-D"))
      assert expected == actual
    end

    test "for Bus line 4" do
      assert "" == safe_to_string(route_icon(3, "4"))
    end
  end

  describe "route_link/3" do
    test "for Orange line", %{conn: conn} do
      route = %Routes.Route{type: 0, id: "Orange", name: "Orange"}

      expected =
        "<a class=\"mode-group-btn\" href=\"/schedules/Orange\">" <>
        safe_to_string(route_icon(route.type, route.id)) <>
        " Orange</a>"

      assert expected == safe_to_string(route_link(conn, route))
    end

    test "for Lowell line", %{conn: conn} do
      route = %Routes.Route{type: 2, id: "CR-Lowell", name: "Lowell"}

      expected = "<a class=\"mode-group-btn\" href=\"/schedules/CR-Lowell\">Lowell</a>"
      assert expected == safe_to_string(route_link(conn, route))
    end

    test "includes additional options", %{conn: conn} do
      route = %Routes.Route{type: 2, id: "CR-Lowell", name: "Lowell"}
      expected = "<a class=\"mode-group-btn\" " <>
        "href=\"/schedules/CR-Lowell?dest=place-sstat&amp;origin=place-harsq\">Lowell</a>"

      assert expected == safe_to_string(
        route_link(conn, route, dest: "place-sstat", origin: "place-harsq"))
    end
  end
end
