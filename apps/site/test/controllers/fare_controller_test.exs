defmodule Site.FareControllerTest do
  use Site.ConnCase

  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, fare_path(conn, :index)
    assert html_response(conn, 200) =~ "Commuter Rail Fares"
  end
end
