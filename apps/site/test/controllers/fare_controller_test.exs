defmodule Site.FareControllerTest do
  use Site.ConnCase

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, fare_path(conn, :index, origin: "place-sstat", destination: "Readville")
    assert html_response(conn, 200) =~ "Commuter Rail Fares"
  end
end
