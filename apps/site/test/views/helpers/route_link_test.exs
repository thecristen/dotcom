defmodule Site.ViewHelpers.RouteLinkTest do
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers, only: [fa: 1]
  import Site.ViewHelpers.RouteLink

  use Site.ConnCase, async: true

  setup %{conn: conn} do
    conn = conn
    |> assign(:date, Util.today)
    |> assign(:alerts, [])
    {:ok, %{conn: conn}}
  end

  describe "route_circle/2" do
    test "for Red line" do
      expected = "circle fa-color-subway-red" |> fa |> safe_to_string
      actual = route_circle(0, "Red")
      assert expected == actual
    end

    test "for Green line D" do
      expected = "circle fa-color-subway-green-d" |> fa |> safe_to_string
      actual = route_circle(1, "Green-D")
      assert expected == actual
    end

    test "for Bus line 4" do
      assert "" == route_circle(3, "4")
    end
  end

  describe "route_link/3" do
    test "for Orange line", %{conn: conn} do
      route = %Routes.Route{type: 0, id: "Orange", name: "Orange"}

      expected =
        "<a class=\"mode-group-btn\" href=\"/schedules/Orange\">" <>
        route_circle(route.type, route.id) <>
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

    test "includes alerts if present", %{conn: conn} do
      route = %Routes.Route{type: 2, id: "CR-Lowell", name: "Lowell"}
      conn = assign(conn, :alerts, [
            %Alerts.Alert{
              effect_name: "Delay",
              informed_entity: [%Alerts.InformedEntity{route_type: 2}],
              active_period: [{Util.now, nil}]}])
      actual = safe_to_string(route_link(conn, route))

      assert actual =~ "There is an alert"
    end
  end
end
