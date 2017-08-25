defmodule Site.SearchControllerTest do
  use Site.ConnCase, async: true
  #import Phoenix.HTML, only: [html_escape: 1, safe_to_string: 1]

  @params %{"search" => %{"query" => "mbta"}}

  describe "index with params" do
    test "only search", %{conn: conn} do
      conn = get conn, search_path(conn, :index, @params)
      response = html_response(conn, 200)
      assert response =~ "Showing results 1-10 of 100"
    end

    test "include offset", %{conn: conn} do
      params = %{@params | "search" => Map.put(@params["search"], "offset", "3")}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "pagination-num active"
    end

    test "include filter", %{conn: conn} do
      content_type = %{"event" => "true"}
      params = %{@params | "search" => Map.put(@params["search"], "content_type", content_type)}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "checked=\"checked\""
    end
  end
end
