defmodule Site.SearchControllerTest do
  use Site.ConnCase, async: true

  @params %{"search" => %{"query" => "mbta"}}

  describe "index with params" do
    test "search param", %{conn: conn} do
      conn = get conn, search_path(conn, :index, @params)
      response = html_response(conn, 200)
      # check pagination
      assert response =~ "Showing results 1-10 of 2083"

      # check highlighting
      assert response =~ "solr-highlight-match"

      # check links from each type of document result
      assert response =~ "/people/2610"
      assert response =~ "/news/1884"
      assert response =~ "/safety/transit-police/office-the-chief"
      assert response =~ "/sites/default/files/2017-01/C. Perkins.pdf"
      assert response =~ "/events/1215"
    end

    test "include offset", %{conn: conn} do
      params = %{@params | "search" => Map.put(@params["search"], "offset", "3")}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "Showing results 31-40 of 2083"
    end

    test "include filter", %{conn: conn} do
      content_type = %{"event" => "true"}
      params = %{@params | "search" => Map.put(@params["search"], "content_type", content_type)}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "<input checked=\"checked\" id=\"content_type_event\" name=\"search[content_type][event]\" type=\"checkbox\" value=\"true\">"
    end

    test "no matches", %{conn: conn} do
      conn = get conn, search_path(conn, :index, %{"search" => %{"query" => "empty"}})
      response = html_response(conn, 200)
      assert response =~ "There are no results matching"
    end
  end
end
