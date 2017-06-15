defmodule Site.RedirectorTest do
  use Site.ConnCase, async: true
  import Phoenix.ConnTest, only: [redirected_to: 1]

  alias Site.Redirector

  test "passes along the redirect path when 'to' is defined" do
    opts = [to: "my-path"]
    assert Redirector.init(opts) == opts
  end

  test "an exception is raised when 'to' is not defined" do
    assert_raise RuntimeError, ~r(Missing required to: option in redirect), fn ->
      Redirector.init([])
    end
  end

  test "route redirected to internal route", %{conn: conn} do
    conn = Redirector.call(conn, to: "/miami")

    assert redirected_to(conn) == "/miami"
  end

  test "route redirected to internal route with query string", %{conn: conn} do
    conn = %{conn | query_string: "food=tapas"}

    conn = Redirector.call(conn, to: "/miami")
    assert redirected_to(conn) == "/miami?food=tapas"
  end

  test "route redirected to /events with a valid id in the params", %{conn: conn} do
    valid_fixture_id = "1"
    conn = %{conn | params: %{"id" => valid_fixture_id}}

    conn = Redirector.call(conn, to: "/events")

    assert conn.halted == true
    assert redirected_to(conn) == event_path(conn, :show, 17)
  end

  test "route redirected to /news with a valid id in the params", %{conn: conn} do
    valid_fixture_id = "1234"
    conn = %{conn | params: %{"id" => valid_fixture_id}}

    conn = Redirector.call(conn, to: "/news")

    assert conn.halted == true
    assert redirected_to(conn) == news_entry_path(conn, :show, 1)
  end

  test "route redirected with an invalid id renders a 404", %{conn: conn} do
    conn =
      conn
      |> Map.merge(%{params: %{"id" => "invalid"}})
      |> put_private(:phoenix_endpoint, Site.Endpoint)

    conn = Redirector.call(conn, to: "/news")

    assert conn.halted == true
    assert conn.status == 404
  end
end
