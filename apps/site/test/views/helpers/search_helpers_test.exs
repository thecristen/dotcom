defmodule Site.SearchHelpersTest do
  use Site.ConnCase, async: true
  import Site.SearchHelpers

  describe "desktop_form/1" do
    test "renders with default text", %{conn: conn} do
      conn = get conn, search_path(conn, :index, %{"search" => %{"query" => "Search Query Format"}})
      response = Phoenix.HTML.safe_to_string(desktop_form(conn))
      assert response =~ "Search Query Format"
    end

    test "renders with search param as a string", %{conn: conn} do
      conn = get conn, search_path(conn, :index, %{"search" => "String Value"})
      response = Phoenix.HTML.safe_to_string(desktop_form(conn))
      refute response =~ "String Value"
    end
  end
end
