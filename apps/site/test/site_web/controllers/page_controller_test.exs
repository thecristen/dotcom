defmodule SiteWeb.PageControllerTest do
  use SiteWeb.ConnCase
  import SiteWeb.PageController

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Massachusetts Bay Transportation Authority"
    assert response_content_type(conn, :html) =~ "charset=utf-8"
  end

  test "body gets assigned a js class", %{conn: conn} do
    [body_class] = build_conn()
      |> get(page_path(conn, :index))
      |> html_response(200)
      |> Floki.find("body")
      |> Floki.attribute("class")
    assert body_class == "no-js"
  end

  test "renders recommended routes if route cookie has a value", %{conn: conn} do
    cookie_name = SiteWeb.Plugs.Cookies.route_cookie_name()
    conn =
      conn
      |> Plug.Test.put_req_cookie(cookie_name, "Red|1|CR-Lowell|Boat-F4")
      |> get(page_path(conn, :index))

    assert Enum.count(conn.assigns.recommended_routes) == 4

    assert [routes_div] =
      conn
      |> html_response(200)
      |> Floki.find(".m-homepage__recommended-routes")

    assert Floki.text(routes_div) =~ "Recently Visited"

    assert [_] = Floki.find(routes_div, ".c-svg__icon-red-line-default")
    assert [_] = Floki.find(routes_div, ".c-svg__icon-mode-bus-default")
    assert [_] = Floki.find(routes_div, ".c-svg__icon-mode-commuter-rail-default")
    assert [_] = Floki.find(routes_div, ".c-svg__icon-mode-ferry-default")
  end

  test "does not render recommended routes if route cookie has no value", %{conn: conn} do
    conn = get(conn, page_path(conn, :index))

    assert Map.get(conn.assigns, :recommended_routes) == nil
    refute html_response(conn, 200) =~ "Recently Visited"
  end

  test "split_whats_happening/1 returns first two if 2+ or 5+" do
    assert split_whats_happening([1, 2]) == {[1, 2], []}
    assert split_whats_happening([1, 2, 3, 4]) == {[1, 2], []}
    assert split_whats_happening([1, 2, 3, 4, 5]) == {[1, 2], [3, 4, 5]}
    assert split_whats_happening([1, 2, 3, 4, 5, 6]) == {[1, 2], [3, 4, 5]}
    assert split_whats_happening([1]) == {nil, nil}
  end
end
